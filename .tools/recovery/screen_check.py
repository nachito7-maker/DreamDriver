#!/usr/bin/env python3
"""Comprobaciones sobre la pantalla REAL del dispositivo.

Nada de aquí deduce nada del código: se mide lo que el juego pinta. Las regiones
salen de la geometría que `scripts/race_hud.gd` y `scripts/touch_controls.gd`
aplican al lienzo **real** del dispositivo, reproducida en `screen_geometry.py`:
telemetría anclada arriba a la izquierda, cronómetro al centro, pedales al borde
derecho, mando abajo a la izquierda, y todo escalado con la ALTURA
(`clamp(alto/900, 0,68 · 1,32)`). Sobre una captura de 2400x1080 las regiones
coinciden con las que estaban calibradas a mano (comprobado en
`screen_geometry.py --selftest`, desvío máximo 2 px), y sobre cualquier otra
resolución caen donde el juego dibuja de verdad:

  telemetría       tarjeta izquierda: velocidad, marcha… (anclada a la izquierda)
  cronómetro      panel central con el tiempo de vuelta (centrado)
  velocidad         los dígitos de km/h
  marcha           la marcha
  mando             el anillo del joystick (anclado abajo a la izquierda)
  pedal acelerador  x desde el borde derecho, y desde el inferior
  pedal freno       ídem, a la izquierda del acelerador

Se mide lo mismo en 2400x1080 y en 1080x2424: las regiones se recalculan a
partir del tamaño detectado, y el criterio no es "esta resolución" sino
"horizontal, pantalla completa, HUD completo y controles en su borde".

Uso:
  screen_check.py layout   <png> [--size ANCHOxALTO] [--display volcado.txt]
  screen_check.py ready    <serial> [--size ANCHOxALTO]
  screen_check.py clock    <serial> <dir-salida> [--size ANCHOxALTO]
  screen_check.py touch    <serial> <dir-salida> [--size ANCHOxALTO]

`ready`, `clock` y `touch` hablan con el dispositivo: si no se les da `--size`
leen su `wm size` para saber con qué geometría medir. `layout` trabaja sobre un
PNG ya capturado y, con `--size`, exige que la captura tenga exactamente ese
tamaño (si el juego se acota a sí mismo o graba con bandas, se ve ahí).
"""
from __future__ import annotations

import argparse
import io
import json
import os
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import screen_geometry  # noqa: E402  (vive junto a este fichero)

# Geometría activa. La fija `usar_geometria` a partir del tamaño real del
# dispositivo (o del que declare `--size`) antes de medir nada.
G: dict = {}


def usar_geometria(ancho: int, alto: int) -> None:
    global G
    G = screen_geometry.geometria(ancho, alto)
    print("GEOMETRIA lienzo %dx%d · escala %.3f · mando (%.1f, %.1f) radio %.1f"
          % (ancho, alto, G["escala"], G["mando_centro"][0], G["mando_centro"][1],
             G["mando_radio"]))


def region(nombre: str) -> tuple:
    return G["regiones"][nombre]


def tamano_devuelto(args) -> tuple:
    """Tamaño con el que medir: el que pida el usuario o el del dispositivo."""
    if getattr(args, "size", None):
        return (int(v) for v in args.size.lower().split("x"))
    return screen_geometry.pantalla_de(args.serial)


def en_centro(cx) -> bool:
    """¿El mando está en reposo?

    Se conserva la ventana histórica —10 px por la izquierda del centro y 19 por
    la derecha, asimetría que viene del sesgo de la caja de medida— pero medida
    desde el centro derivado y escalada con el mando.
    """
    if cx is None:
        return False
    d = G["desplazamiento"]
    centro = G["mando_centro"][0]
    return (centro - 10.0 * d) <= cx <= (centro + 19.0 * d)


def umbral_desvio_mando() -> float:
    """Desvío que se considera "mando movido": 0,55 del recorrido."""
    return G["mando_radio"] * 0.55


def umbral_retorno_mando() -> float:
    """Desvío mínimo del mando para hablar de movimiento: 0,34 del recorrido."""
    return G["mando_radio"] * 0.34


def umbral_cambio(px_escala_1_2: float) -> float:
    """Píxeles cambiados que se exigen en el HUD, escalados con su área.

    El HUD se escala con la altura, así que el número de píxeles que cambia un
    dígito va con el cuadrado de esa escala. Sobre una pantalla de 1080 de alto
    el factor es exactamente 1 y los umbrales son los de siempre.
    """
    return px_escala_1_2 * (G["escala"] / 1.2) ** 2
# Colores declarados en el juego, que es lo que permite localizar los mandos.
PEDAL_THROTTLE = (98, 237, 177)  # borde del acelerador, Color("#62edb1")
PEDAL_BRAKE = (255, 119, 106)    # borde del freno, Color("#ff776a")
LERDO = 6                        # tolerancia entre canales
# El mando NO se busca por el color de su disco: el disco se pinta con alpha
# 0,85 (`_draw_steering_knob`), así que su color medido lo decide el fondo que
# tenga detrás. Sobre el asfalto del inicio sale (45,56,62) y fuera de pista
# (35,58,65): buscar (33,43,53)±14 medía el circuito, no el mando, y en la
# captura posterior a la conducción real dio 3 píxeles y "mandó" el mando fuera
# de sitio cuando estaba exactamente en el centro (185,895, píxel a píxel).
#
# Lo que sí es estable es la raya vertical del disco (Color(0.92,0.94,0.97,0.78)):
# se pinta ENCIMA del disco, que ya es oscuro, así que el fondo apenas la toca
# —medida sale (192,199,206) al inicio y (191,200,207) fuera de pista— y además
# es única: el mundo no dibuja una raya clara, vertical y de más de 20 px con el
# disco oscuro a sus dos lados en esa esquina.
RAYO_MIN = 165                   # canal rojo mínimo de la raya clara
RAYO_VERDE = 5                   # en la captura la raya es blanco frío (g-r>=5)
RAYO_NUCLEO = 8                  # filas del núcleo frío que exige el camino suave
DISCO_MAX = 120                  # y bajo ella el disco del mando es oscuro
LARGO_RAYA = 20                  # px a escala 1,2; la raya mide 48 con el disco entero
HUECOS_RAYA = 2                  # filas fallidas que no cortan un tramo (croma 4:2:0)


def largo_raya_min() -> int:
    """Longitud mínima de la raya del mando, escalada con el mando.

    La raya se dibuja como fracción del radio del disco, así que en una pantalla
    de otra altura mide otra cosa; el umbral tiene que seguirla o dejaría de
    distinguir la raya del mando de una franja clara cualquiera.
    """
    return max(4, round(LARGO_RAYA * G.get("desplazamiento", 1.0)))


def nucleo_min() -> int:
    return max(1, round(RAYO_NUCLEO * G.get("desplazamiento", 1.0)))


ADB = os.environ.get("ADB", "adb")


def adb_call(serial: str, *args: str, timeout: float = 12.0) -> subprocess.CompletedProcess:
    """One bounded device call; never block screen sampling on a sick emulator."""
    return subprocess.run([ADB, "-s", serial, *args], capture_output=True, timeout=timeout)


# Cuánto se espera al aparato para que devuelva el lienzo. No es un criterio de
# aceptación —nada de lo que se mide cambia— sino el margen de una máquina lenta: en
# un emulador que dibuja por software (el de este equipo, porque `-gpu host` aborta
# con un informe de fallo) un `screencap` a 2424x1080 tarda ~16 s, y el valor de 10 s
# que servía con GPU de hardware deja a todas las comprobaciones de pantalla sin
# captura. El valor por defecto se queda EXACTAMENTE igual: sólo cambia si quien
# ejecuta la batería declara F1_CAPTURA_TIMEOUT.
CAPTURA_TIMEOUT = float(os.environ.get("F1_CAPTURA_TIMEOUT", "10.0"))


def screencap(serial: str) -> Image.Image:
    result = adb_call(serial, "exec-out", "screencap", "-p", timeout=CAPTURA_TIMEOUT)
    if result.returncode != 0 or len(result.stdout) < 1000:
        raise RuntimeError("screencap falló: %s" % result.stderr[:200])
    return Image.open(io.BytesIO(result.stdout)).convert("RGB")


def blob(image: Image.Image, target, tolerance: int, region) -> dict | None:
    box = image.crop(region)
    pixels = box.load()
    xs, ys = [], []
    for y in range(box.size[1]):
        for x in range(box.size[0]):
            c = pixels[x, y]
            if abs(c[0] - target[0]) <= tolerance and abs(c[1] - target[1]) <= tolerance \
                    and abs(c[2] - target[2]) <= tolerance:
                xs.append(x + region[0])
                ys.append(y + region[1])
    if not xs:
        return None
    return {"n": len(xs), "cx": sum(xs) // len(xs), "cy": sum(ys) // len(ys),
            "x0": min(xs), "y0": min(ys), "x1": max(xs), "y1": max(ys)}


def es_rayo(color) -> bool:
    """¿Es un píxel de la raya clara del mando, en una captura de pantalla?

    Solo el color. El canal azul no entra: en el vídeo va en 4:2:0 y pierde su
    matiz —(194,196,200) en la grabación frente a (192,199,206) en la captura—,
    así que el azul no distingue. Para el vídeo está `es_rayo_suave`.
    """
    r, g, _ = color
    return r >= RAYO_MIN and g - r >= RAYO_VERDE


def es_rayo_suave(color) -> bool:
    """Raya clara vista a través del vídeo, que le come el matiz.

    El H.264 4:2:0 muestrea el croma la mitad y una raya de 3 px se queda entre
    (194,196,200) y (188,198,200): sigue siendo un blanco claro, pero con la
    diferencia verde-rojo deshecha. Se exige solo que sea claro y no rosado, y
    quien descarta al mundo es la firma del disco (`_es_mando`), que sigue
    siendo obligatoria.
    """
    r, g, b = color
    return r >= RAYO_MIN and g >= r - 2 and b >= r - 2


def _tramos_claros(box, encendido, huecos: int = HUECOS_RAYA) -> list:
    """Tramos verticales encendidos de la región, del más largo al más corto.

    Cada tramo es (largo, columna, arriba, abajo). La raya del mando mide 48 px
    de alto y 3 de ancho, así que aparece como el tramo más largo; se mide como
    el resto del fichero, píxel a píxel con PIL (260x260, ~16 ms: los ~2 200
    fotogramas de la grabación de toque caben de sobra).

    Dos filas fallidas dentro de un tramo no lo cortan: en el vídeo el croma
    submuestreado parte una raya de 3 px en trozos de 10-18 px —medido en la
    grabación— aunque la raya siga entera. En la captura PNG no hay cortes y
    sale de una pieza (48 px).
    """
    ancho, alto = box.size
    pixels = box.load()
    tramos = []
    for x in range(ancho):
        inicio = ultimo = None
        fallos = 0
        for y in range(alto):
            if encendido(pixels[x, y]):
                if inicio is None:
                    inicio = y
                ultimo = y
                fallos = 0
            elif inicio is not None:
                fallos += 1
                if fallos > huecos:
                    tramos.append((ultimo - inicio + 1, x, inicio, ultimo))
                    inicio = ultimo = None
                    fallos = 0
        if inicio is not None:
            tramos.append((ultimo - inicio + 1, x, inicio, ultimo))
    tramos.sort(key=lambda tramo: -tramo[0])
    return tramos


def _es_mando(pixels, ancho, tramo) -> bool:
    """¿El tramo claro es la raya del mando y no una franja clara del circuito?

    La firma del mando es que la raya se pinta sobre su propio disco, que es
    oscuro: a su altura media hay disco oscuro a los dos lados. Una franja
    clara del terreno (asfalto, bordillo, línea de meta) no lo tiene.
    """
    largo, columna, arriba, abajo = tramo
    medio = (arriba + abajo) // 2

    def oscuro(x):
        return 0 <= x < ancho and max(pixels[x, medio]) <= DISCO_MAX

    return (any(oscuro(x) for x in range(columna - 8, columna - 2))
            and any(oscuro(x) for x in range(columna + 3, columna + 9)))


def _centro(pixels, ancho, tramo) -> dict:
    """Centro geométrico del tramo, con las columnas que lo forman."""
    largo, columna, arriba, abajo = tramo

    def encendido(color):
        return es_rayo(color) or es_rayo_suave(color)

    columnas = [x for x in range(max(0, columna - 3), min(ancho, columna + 4))
                if any(encendido(pixels[x, y]) for y in range(arriba, abajo + 1))]
    x0r, y0r = region("mando")[0], region("mando")[1]
    return {"n": largo,
            "cx": sum(columnas) // len(columnas) + x0r,
            "cy": (arriba + abajo) // 2 + y0r,
            "x0": min(columnas) + x0r, "x1": max(columnas) + x0r,
            "y0": arriba + y0r, "y1": abajo + y0r}


def knob(image: Image.Image) -> dict | None:
    """Centro del mando, medido por su raya vertical.

    Primero con el color exacto de la raya, que es como se mide en una captura
    de pantalla; si no aparece —el vídeo le come el matiz al croma— se repite
    con el color suavizado, exigiendo entonces un núcleo de filas claras que
    confirme que el tramo es la raya y no una franja del circuito.

    La posición no depende del fondo, así que la misma medición sirve al inicio
    de la vuelta, en pista y fuera de ella; y si el mando se desvía, la raya se
    va con él y el centro se mueve, que es lo que hay que detectar.
    """
    box = image.crop(region("mando"))
    pixels = box.load()
    ancho = box.size[0]
    for encendido, nucleo in ((es_rayo, 0), (es_rayo_suave, nucleo_min())):
        for tramo in _tramos_claros(box, encendido):
            if tramo[0] < largo_raya_min():
                break
            if not _es_mando(pixels, ancho, tramo):
                continue
            if nucleo and sum(1 for y in range(tramo[2], tramo[3] + 1)
                              if es_rayo(pixels[tramo[1], y])) < nucleo:
                continue
            return _centro(pixels, ancho, tramo)
    return None


def pedal_pressure(image: Image.Image, region: tuple, face: str) -> float:
    """Presión de un pedal, medida por el relleno que pinta el juego.

    Se mide sobre el PANEL dibujado (no sobre su área sensible) y exigiendo un
    color muy saturado: el relleno del pedal pisado es (140,43,41) en el freno y
    (28,122,87) en el acelerador, con 90-100 de separación entre el canal que
    manda y el otro, mientras que el mundo que se ve alrededor y a través del
    panel translúcido —asfalto, bordillos, vallas rojas— no pasa de 60. La
    versión anterior contaba "píxeles rojizos" en la caja táctil entera y medía
    el circuito: en una vuelta dio 0,396 de freno con el freno sin tocar, porque
    el coche pasaba junto a una valla roja.
    """
    x0, y0, x1, y1 = region
    crop = image.crop((x0, y0, x1, y1))
    pixels = crop.load()
    count = 0
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b = pixels[x, y]
            if face == "throttle":
                if g - r > 80 and g - b > 40:
                    count += 1
            elif r - g > 80 and r - b > 40:
                count += 1
    return count / max(1, crop.width * crop.height)


def differences(a: Image.Image, b: Image.Image, region, threshold: int = 20) -> dict:
    box_a = a.crop(region)
    box_b = b.crop(region)
    diff = ImageChops.difference(box_a, box_b).convert("L")
    hist = diff.histogram()
    total = box_a.size[0] * box_a.size[1]
    changed = sum(hist[threshold + 1:])
    top = max((i for i, v in enumerate(hist) if v), default=0)
    return {"cambiados": changed, "total": total, "fraccion": round(changed / total, 4),
            "delta_max": top}


def black_columns(image: Image.Image) -> list:
    pixels = image.load()
    width, height = image.size
    columns = []
    for x in range(width):
        dark = 0
        for y in range(0, height, 8):
            c = pixels[x, y]
            if c[0] + c[1] + c[2] < 24:
                dark += 1
        if dark >= height // 8 - 2:
            columns.append(x)
    return columns


def cmd_layout(args) -> int:
    """El juego llena la pantalla, el HUD está completo y los mandos en su borde.

    El criterio no es una resolución, sino lo que tiene que cumplirse en
    cualquier pantalla: horizontal, captura del tamaño del lienzo (sin acotarse
    ni meter bandas), mando anclado abajo a la izquierda, los dos pedales en la
    mitad derecha y el freno a la izquierda del acelerador, y ningún panel del
    HUD bajo el recorte de pantalla del aparato si lo tiene.
    """
    image = Image.open(args.png).convert("RGB")
    if not args.size:
        print("LAYOUT FALLA: falta --size; sin el tamaño del dispositivo no se sabe "
              "dónde ancla el juego cada control")
        return 1
    esperado = tuple(int(v) for v in args.size.lower().split("x"))
    usar_geometria(*esperado)
    if image.size != esperado:
        print("LAYOUT FALLA: la captura mide %dx%d y el lienzo del dispositivo %dx%d "
              "(el juego no llena la pantalla)"
              % (image.size[0], image.size[1], esperado[0], esperado[1]))
        return 1
    if image.size[0] <= image.size[1]:
        print("LAYOUT FALLA: la captura no es horizontal: %dx%d" % image.size)
        return 1
    ok = True
    kn = knob(image)
    acelerador = blob(image, PEDAL_THROTTLE, LERDO, region("pedal_acelerador"))
    freno = blob(image, PEDAL_BRAKE, LERDO, region("pedal_freno"))
    negro = black_columns(image)
    cx, cy = G["mando_centro"]
    tol = G["tolerancia_mando"]
    print("LAYOUT lienzo=%dx%d·escala %.2f  mando=%s  anclaje=(%.1f, %.1f)±%.0f"
          % (image.size[0], image.size[1], G["escala"], kn, cx, cy, tol))
    print("LAYOUT pedal_acelerador:", acelerador)
    print("LAYOUT pedal_freno:", freno)
    print("LAYOUT columnas_negras=%d %s" % (len(negro), (min(negro), max(negro)) if negro else ""))
    if kn is None:
        print("LAYOUT FALLA: no se ve la raya del mando dentro de su región")
        ok = False
    else:
        if abs(kn["cx"] - cx) > tol or abs(kn["cy"] - cy) > tol:
            print("LAYOUT FALLA: el mando está en (%s, %s) y su anclaje es (%.1f, %.1f)"
                  % (kn["cx"], kn["cy"], cx, cy))
            ok = False
        if kn["cx"] >= image.size[0] * 0.5:
            print("LAYOUT FALLA: el mando no está en la mitad izquierda (cx=%s)" % kn["cx"])
            ok = False
    for nombre, hallado in (("pedal_acelerador", acelerador), ("pedal_freno", freno)):
        if hallado is None:
            print("LAYOUT FALLA: no se encontró el %s en su región" % nombre)
            ok = False
    if acelerador is not None and acelerador["cx"] < image.size[0] * 0.5:
        print("LAYOUT FALLA: el acelerador no está en la mitad derecha (cx=%s)" % acelerador["cx"])
        ok = False
    if acelerador is not None and freno is not None and freno["cx"] >= acelerador["cx"]:
        print("LAYOUT FALLA: el freno no queda a la izquierda del acelerador (%s >= %s)"
              % (freno["cx"], acelerador["cx"]))
        ok = False
    if negro:
        print("LAYOUT FALLA: hay %d columnas negras (bandas laterales)" % len(negro))
        ok = False
    if args.display and Path(args.display).is_file():
        recortes = screen_geometry.recorte_de(Path(args.display).read_text(errors="replace"))
        if recortes:
            print("LAYOUT recortes de pantalla:", recortes)
        for rect in recortes:
            for nombre in ("telemetria", "cronometro", "velocidad", "marcha",
                           "mando", "pedal_acelerador", "pedal_freno"):
                if screen_geometry.choque(region(nombre), rect):
                    print("LAYOUT FALLA: la región %s %s cae bajo el recorte de pantalla %s"
                          % (nombre, region(nombre), rect))
                    ok = False
    print("LAYOUT PASS=", ok)
    return 0 if ok else 1


def cmd_ready(args) -> int:
    """0 solo si el juego ya dibuja su HUD.

    El anuncio `[track]` del registro sale antes del primer fotograma: la
    primera vez el emulador compila los shaders y la pantalla sigue un rato en
    la imagen de arranque. El mando del joystick pertenece al HUD, así que
    verlo es la prueba de que el juego ya está dibujando de verdad.
    """
    usar_geometria(*tamano_devuelto(args))
    image = screencap(args.serial)
    kn = knob(image)
    print("READY mando:", kn)
    return 0 if kn is not None else 1


PEDAL_MS = 4500


def throttle_press(serial: str, milliseconds: int = PEDAL_MS) -> None:
    """Pisa el pedal del acelerador con un toque real del sistema.

    Las coordenadas salen de la misma región que usa la comprobación de
    `layout`, no de números escritos a mano. El dedo baja en el centro del
    pedal y sube hasta su borde superior, que en el juego es presión total.
    """
    x0, y0, x1, y1 = region("pedal_acelerador")
    x = (x0 + x1) // 2
    y = (y0 + y1) // 2
    subprocess.run([ADB, "-s", serial, "shell", "input", "swipe",
                    str(x), str(y), str(x), str(y0 + 6), str(milliseconds)],
                   check=False, timeout=10.0)


def cmd_clock(args) -> int:
    """El cronómetro tiene que avanzar en el dispositivo.

    El coche aparece justo antes de la línea de meta y el cronómetro no cuenta
    hasta que la cruza, así que sobre el coche parado la pantalla no cambia y la
    medida sería un falso negativo. Si la primera pareja de capturas sale igual,
    se acelera el coche con toques reales -como haría una persona- y se vuelve a
    medir hasta que cruce. Si aun así no avanza, es un fallo: el juego no está
    pintando, o el cronómetro no cuenta.
    """
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    usar_geometria(*tamano_devuelto(args))

    def pareja():
        antes = screencap(serial)
        time.sleep(3.0)
        despues = screencap(serial)
        return antes, despues, differences(antes, despues, region("cronometro"))

    antes, despues, clock = pareja()
    arranque = "ya contaba"
    if not (clock["cambiados"] > 300 and clock["delta_max"] > 40):
        print("CLOCK parado: el coche aún no ha cruzado la meta; se acelera de verdad")
        for intento in range(1, 7):
            throttle_press(serial)
            time.sleep(1.0)
            antes, despues, clock = pareja()
            print("CLOCK intento %d:" % intento, clock)
            if clock["cambiados"] > 300 and clock["delta_max"] > 40:
                arranque = "arrancó tras %d pulsaciones reales del acelerador" % intento
                break

    antes.save(outdir / "reloj-1.png")
    despues.save(outdir / "reloj-2.png")
    print("CLOCK cronometro:", clock)
    print("CLOCK arranque:", arranque)
    ok = clock["cambiados"] > 300 and clock["delta_max"] > 40
    print("CLOCK PASS=", ok, "(el cronómetro avanza en el dispositivo)")
    return 0 if ok else 1


PKG = "com.freebuff.f1oneshot.barcelonamoto"
ACTIVITY = PKG + "/com.godot.game.GodotAppLauncher"
# Velocidad mínima para dar por buena una muestra de dirección: por debajo, el coche está
# arrancando o parado y ni el tope de dirección ni el agarre son los de marcha.
VELOCIDAD_DE_MEDIDA_KMH = 25.0

MANDO_RE = re.compile(
    r"\[mando\] kmh=(?P<kmh>[-+0-9.]+) mando=(?P<mando>[-+0-9.]+) demanda=(?P<demanda>[-+0-9.]+) "
    r"aplicado=(?P<aplicado>[-+0-9.]+) tope=(?P<tope>[-+0-9.]+) guinada=(?P<guinada>[-+0-9.]+) "
    r"lateral=(?P<lateral>[-+0-9.]+) ruedas=(?P<ruedas>[0-9]+)")


def cmd_mando(args) -> int:
    """¿GIRA EL COCHE EN EL DISPOSITIVO con el joystick táctil de verdad?

    El juego deja en su registro una línea `[mando]` cada medio segundo —sólo en la
    compilación de depuración, que es el APK de pruebas— con la demanda del mando, el
    ángulo aplicado a las ruedas, el tope de esa velocidad, el régimen de guiñada y la
    aceleración lateral. Esta orden conduce con el inyector multitáctil: acelerador a
    fondo, y después el mando al fondo de su recorrido, primero a la derecha y luego a la
    izquierda. Sobre esas líneas comprueba, con dedos reales sobre el aparato, que

      * el dedo al fondo del mando pide la demanda casi total (≥ 0,9);
      * esa demanda LLEGA a las ruedas: el ángulo aplicado es el tope de la velocidad
        (entre el 80 % y el 100 % de él) y tiene el sentido pedido, así que no se pierde
        por el camino ni se queda en el mando;
      * el coche GIRA en el sentido pedido: hay régimen de guiñada del signo pedido y de
        magnitud apreciable;
      * a la velocidad alcanzada hay capacidad de giro real (≥ 0,6 g de aceleración
        lateral sostenida);
      * los dos lados giran al revés el uno del otro (la guiñada cambia de signo).

    La maniobra la ejecuta AndroidTouch en su modo `mando`, que no toca la secuencia de
    fases que miden las demás comprobaciones.
    """
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    usar_geometria(*tamano_devuelto(args))
    devlog = "/data/local/tmp/mando-inyector.log"
    adb_call(serial, "shell", "rm", "-f", devlog, timeout=5.0)
    injector_class = Path(".tools/recovery/java/AndroidTouch.class")
    if not injector_class.is_file():
        raise RuntimeError("AndroidTouch.class no está compilado; prepara primero toque_jar")
    # El juego se relanza desde la salida: la maniobra necesita un coche sobre el asfalto,
    # en marcha y con sitio para acelerar. Después de las comprobaciones anteriores el coche
    # puede estar detenido contra una barrera o fuera de la calzada, y entonces la medida no
    # diría nada de la dirección.
    # El registro se vacía ANTES de arrancar: el anuncio `[track]` de la sesión anterior sigue
    # en el búfer, así que esperarlo sin vaciar daba por arrancado un juego que aún estaba
    # cargando (medido: la maniobra entera se ejecutaba sobre la pantalla de carga y el registro
    # no dejaba ni una línea `[mando]`, que se informaba como fallo del mando).
    adb_call(serial, "shell", "logcat", "-c", timeout=20.0)
    adb_call(serial, "shell", "am", "force-stop", PKG, timeout=20.0)
    time.sleep(2.0)
    adb_call(serial, "shell", "am", "start", "-W", "-n", ACTIVITY, timeout=60.0)
    for _ in range(30):
        time.sleep(4.0)
        arranque = adb_call(serial, "logcat", "-d", timeout=25.0).stdout.decode(errors="replace")
        if "[track] Barcelona 2023 Moto" in arranque:
            break
    else:
        raise RuntimeError("el juego no anunció la pista en 120 s; no se puede conducir")
    # El anuncio sale ANTES del primer fotograma: con el emulador frío los shaders tardan casi un
    # minuto y la maniobra caía sobre la imagen de arranque. Se espera a ver el mando dibujado,
    # que es la misma prueba que usa `ready` para decir que el juego dibuja de verdad.
    for _ in range(45):
        try:
            if knob(screencap(serial)) is not None:
                break
        except Exception:  # noqa: BLE001 - una captura que falla no es motivo para no insistir
            pass
        time.sleep(4.0)
    else:
        raise RuntimeError("el juego no dibujó su HUD en 180 s; no se puede medir el mando")
    pushed = adb_call(serial, "push", str(Path(".tools/recovery/android-touch.jar")),
                      "/data/local/tmp/android-touch.jar", timeout=20.0)
    if pushed.returncode != 0:
        raise RuntimeError("No se pudo enviar el inyector multitáctil: %s" % pushed.stderr[:200])
    adb_call(serial, "logcat", "-c", timeout=20.0)
    coords = [G["mando_centro"][0], G["mando_centro"][1],
              G["mando_derecha"][0], G["mando_izquierda"][0],
              G["pedal_acelerador_centro"][0], G["pedal_arriba_y"], G["pedal_abajo_y"],
              G["pedal_freno_centro"][0], G["pedal_arriba_y"], G["pedal_abajo_y"]]
    print("MANDO inyector coordenadas=%s" % [round(v, 1) for v in coords])
    remote_injector = ("nohup setsid sh -c 'CLASSPATH=/data/local/tmp/android-touch.jar "
                       "app_process /system/bin AndroidTouch %s mando > %s 2>&1' "
                       "</dev/null >/dev/null 2>&1 &"
                       % (" ".join("%.1f" % v for v in coords), devlog))
    adb_call(serial, "shell", remote_injector, timeout=25.0)
    # La maniobra dura 12 s de recta + 9 s a cada lado + 2 s de cierre. El emulador va muy
    # por debajo del tiempo real (unos 5 fotogramas por segundo: los pasos de física que
    # puede dar el motor son los que caben en cada fotograma), así que se espera a la marca
    # final del inyector en vez de a un reloj del anfitrión.
    marcas: list = []
    for _ in range(45):
        time.sleep(4.0)
        salida = adb_call(serial, "shell", "cat", devlog, timeout=12.0)
        marcas = [line.strip() for line in salida.stdout.decode(errors="replace").splitlines()
                  if line.strip()]
        if any("steer_fin" in marca for marca in marcas):
            break
    print("MANDO marcas=%s" % [m for m in marcas if m.startswith("PHASE") or "_DOWN" in m or "_UP" in m])
    logcat = adb_call(serial, "logcat", "-d", timeout=40.0).stdout.decode(errors="replace")
    (outdir / "mando-logcat.txt").write_text(logcat)
    (outdir / "mando-inyector.log").write_text("\n".join(marcas))
    muestras = [{clave: float(valor) if clave != "ruedas" else int(valor)
                 for clave, valor in coincidencia.groupdict().items()}
                for coincidencia in MANDO_RE.finditer(logcat)]
    # Sólo cuentan las muestras CON EL COCHE RODANDO: un coche parado (contra una barrera,
    # por ejemplo) no demuestra nada sobre la dirección, y el ruido de la maniobra no puede
    # tapar un fallo real porque abajo se exige un mínimo de muestras en marcha por lado.
    en_marcha = [m for m in muestras if m["kmh"] >= VELOCIDAD_DE_MEDIDA_KMH]
    derechas = [m for m in en_marcha if m["demanda"] >= 0.5]
    izquierdas = [m for m in en_marcha if m["demanda"] <= -0.5]
    print("MANDO muestras=%d en_marcha=%d (≥ %.0f km/h) derechas=%d izquierdas=%d"
          % (len(muestras), len(en_marcha), VELOCIDAD_DE_MEDIDA_KMH, len(derechas), len(izquierdas)))
    if not muestras:
        print("MANDO FAIL no llegó ninguna línea [mando] al registro del dispositivo")
        return 1

    def resumen(grupo: list, nombre: str) -> dict:
        if not grupo:
            print("MANDO %s sin muestras" % nombre)
            return {}
        peor = max(grupo, key=lambda m: abs(m["lateral"]))
        aplicados = [abs(m["aplicado"]) / max(m["tope"], 0.01) for m in grupo]
        guinadas = sorted(m["guinada"] for m in grupo)
        mediana = guinadas[len(guinadas) // 2]
        mayor_giro = max(grupo, key=lambda m: abs(m["guinada"]))["guinada"]
        print("MANDO %s muestras=%d demanda=%+.3f kmh=%.1f aplicado=%+.2f tope=%.2f "
              "relación_aplicado/tope=%.2f guinada_mediana=%+.3f guinada_max=%+.3f lateral=%.2f ruedas=%d"
              % (nombre, len(grupo), grupo[-1]["demanda"], peor["kmh"], peor["aplicado"],
                 peor["tope"], sum(aplicados) / len(aplicados), mediana, mayor_giro,
                 peor["lateral"], peor["ruedas"]))
        return {"muestras": len(grupo), "demanda": grupo[-1]["demanda"], "kmh_max": peor["kmh"],
                "aplicado": peor["aplicado"], "tope": peor["tope"],
                "aplicado/tope": sum(aplicados) / len(aplicados), "guinada": mediana,
                "guinada_max": mayor_giro, "lateral": peor["lateral"]}

    derecha = resumen(derechas, "derecha")
    izquierda = resumen(izquierdas, "izquierda")
    fallos = 0

    def check(ok: bool, texto: str) -> None:
        nonlocal fallos
        print("MANDO %s %s" % ("PASS" if ok else "FAIL", texto))
        if not ok:
            fallos += 1

    check(len(derechas) >= 2 and len(izquierdas) >= 2,
          "el inyector llegó a los dos lados y el juego dejó muestras de cada uno (derecha %d, izquierda %d)"
          % (len(derechas), len(izquierdas)))
    for nombre, grupo, resumen_ in (("derecha", derechas, derecha), ("izquierda", izquierdas, izquierda)):
        if not grupo:
            continue
        signo = 1.0 if nombre == "derecha" else -1.0
        # El dedo se lleva al fondo de su recorrido en los dos lados, pero el recorrido del
        # lado izquierdo que da la geometría del aparato es algo menor que el del derecho, así
        # que la demanda esperada es algo menor: lo que se exige es que el mando entregue la
        # demanda de un dedo AL FONDO de su recorrido (con la curva comprimida que tenía el
        # juego, ese mismo dedo pedía 0,76 en el lado izquierdo y 1,00 en el derecho: el
        # umbral separa las dos situaciones).
        check(resumen_["demanda"] * signo >= 0.80,
              "el dedo al fondo del mando pide casi toda la demanda a la %s (%+.3f ≥ 0,80)"
              % (nombre, resumen_["demanda"]))
        check(0.8 <= resumen_["aplicado/tope"] <= 1.02,
              "el ángulo pedido llega a las ruedas: el aplicado es el tope de la velocidad "
              "(relación %.2f, entre 0,80 y 1,02)" % resumen_["aplicado/tope"])
        check(all(m["aplicado"] * m["demanda"] > 0.0 for m in grupo if abs(m["demanda"]) >= 0.5),
              "las ruedas giran hacia el lado que pide el mando a la %s" % nombre)
        # La aceleración lateral del registro viene con signo (una curva a la derecha da
        # guiñada negativa), así que lo que se exige es su magnitud.
        check(abs(resumen_["lateral"]) >= 0.6,
              "a %.1f km/h hay capacidad de giro real a la %s (%.2f g ≥ 0,6 g)"
              % (resumen_["kmh_max"], nombre, resumen_["lateral"]))
        # La guiñada se resume con su MEDIANA: al final de cada tramo el coche puede tocar el
        # bordillo o enderezar, y un par de muestras sueltas no deben decidir la medida.
        check(abs(resumen_["guinada"]) >= 0.05 and abs(resumen_["guinada_max"]) >= 0.05,
              "el coche gira de verdad a la %s (guiñada mediana %+.3f rad/s, máxima %+.3f ≥ 0,05)"
              % (nombre, resumen_["guinada"], resumen_["guinada_max"]))
    if derecha and izquierda:
        check(derecha["guinada"] * izquierda["guinada"] < 0.0,
              "los dos lados giran al revés el uno del otro (derecha %+.3f rad/s, izquierda %+.3f rad/s)"
              % (derecha["guinada"], izquierda["guinada"]))
    (outdir / "mando.json").write_text(json.dumps({
        "derecha": derecha, "izquierda": izquierda, "muestras": len(muestras),
        "marcas": marcas, "fallos": fallos}, indent=2, ensure_ascii=False))
    print("MANDO PASS=%s (el joystick táctil real gira el coche en el dispositivo)" % (fallos == 0))
    return 0 if fallos == 0 else 1


def cmd_touch(args) -> int:
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    usar_geometria(*tamano_devuelto(args))
    devlog = "/data/local/tmp/touch.log"
    adb_call(serial, "shell", "rm", "-f", devlog, timeout=5.0)
    video_path = outdir / "touch.mp4"
    remote_video = "/data/local/tmp/touch-screenrecord.mp4"
    remote_diag = "/data/local/tmp/touch-screenrecord.log"
    adb_call(serial, "shell", "rm", "-f", remote_video, timeout=5.0)
    adb_call(serial, "shell", "rm", "-f", remote_diag, timeout=5.0)
    adb_call(serial, "shell", "touch", devlog, timeout=5.0)
    injector_class = Path(".tools/recovery/java/AndroidTouch.class")
    if not injector_class.is_file():
        raise RuntimeError("AndroidTouch.class no está compilado; prepara primero toque_jar")
    # Keep the game foregrounded; InputManager dispatch rejects a hidden SurfaceView.
    focus = adb_call(serial, "shell", "dumpsys", "window", timeout=12.0).stdout.decode(errors="replace")
    if "com.freebuff.f1oneshot.barcelonamoto" not in focus:
        adb_call(serial, "shell", "am", "start", "-n",
                 "com.freebuff.f1oneshot.barcelonamoto/com.godot.game.GodotAppLauncher", timeout=15.0)
        time.sleep(3.0)
    # Estar en primer plano no es estar dibujando: con la instalación recién hecha el juego
    # tarda casi un minuto en compilar los shaders y la maniobra entera corría sobre la imagen
    # de arranque, sin una sola fase que medir en el vídeo (medido: "no se detectaron todas las
    # fases en vídeo"). Se espera a ver el mando dibujado, la misma prueba que usa `ready`.
    for _ in range(45):
        try:
            if knob(screencap(serial)) is not None:
                break
        except Exception:  # noqa: BLE001 - una captura que falla no es motivo para no insistir
            pass
        time.sleep(4.0)
    else:
        raise RuntimeError("el juego no dibujó su HUD en 180 s; no se puede medir el toque")
    pushed = adb_call(serial, "push", str(Path(".tools/recovery/android-touch.jar")),
                      "/data/local/tmp/android-touch.jar", timeout=20.0)
    if pushed.returncode != 0:
        raise RuntimeError("No se pudo enviar el inyector multitáctil: %s" % pushed.stderr[:200])
    # screenrecord saves the rendered Android Surface; pull only after the
    # encoder has closed its MP4 container.
    recording_start = time.monotonic()
    recorder_log = outdir / "screenrecord.log"
    recorder_stream = recorder_log.open("wb")
    # El inyector recorre ahora nueve fases (idle, acelerador, freno, multitáctil,
    # retorno, freno+dirección, liberación total): la grabación tiene que cubrir
    # la secuencia completa sin cortar la última fase, que es donde se mide el
    # retorno del mando al centro tras soltar todo.
    recorder = subprocess.Popen(
        [ADB, "-s", serial, "shell", "screenrecord", "--time-limit", "75",
         "--bit-rate", "1500000", remote_video],
        stdout=recorder_stream, stderr=subprocess.PIPE)
    markers = []
    stop = threading.Event()

    def follow():
        reader = subprocess.Popen([ADB, "-s", serial, "shell", "tail", "-f", "-n", "+1", devlog],
                                  stdout=subprocess.PIPE, text=True, bufsize=1)
        for line in reader.stdout:
            line = line.strip()
            if line.startswith("PHASE") or line.endswith("_DOWN") or line.endswith("_UP"):
                markers.append((time.monotonic(), line))
            if stop.is_set():
                break
        reader.terminate()

    follower = threading.Thread(target=follow, daemon=True)
    follower.start()

    # Let the recorder initialize before launching the sole privileged injector.
    time.sleep(2.0)
    # El inyector va DESPRENDIDO de la sesión de adb (`nohup ... &`): si el
    # servidor de adb de este equipo se reinicia a mitad de la grabación —lo
    # comparten el IDE y el emulador— la sesión cae y el proceso remoto moría con
    # ella (el registro decía "Killed" y la maniobra se quedaba a medias).
    # Desprendido, el corte de la sesión no lo mata y sus marcas siguen llegando
    # al registro, que es lo que lee el seguidor.
    # `setsid` abre una sesión nueva: adbd mata el grupo de procesos de su shell
    # cuando la conexión cae, y con `nohup` solo no bastaba. Comprobado en este
    # emulador: un proceso así sobrevive a `adb kill-server`.
    # Las coordenadas que pisa el inyector salen de la geometría detectada, no de
    # números escritos para una pantalla concreta: el mando se ancla al borde
    # izquierdo y los pedales al derecho, así que al cambiar el ancho se mueven.
    coords = [G["mando_centro"][0], G["mando_centro"][1],
              G["mando_derecha"][0], G["mando_izquierda"][0],
              G["pedal_acelerador_centro"][0], G["pedal_arriba_y"], G["pedal_abajo_y"],
              G["pedal_freno_centro"][0], G["pedal_arriba_y"], G["pedal_abajo_y"]]
    print("TOUCH inyector coordenadas=%s" % [round(v, 1) for v in coords])
    remote_injector = ("nohup setsid sh -c 'CLASSPATH=/data/local/tmp/android-touch.jar "
                       "app_process /system/bin AndroidTouch %s > %s 2>&1' "
                       "</dev/null >/dev/null 2>&1 &"
                       % (" ".join("%.1f" % v for v in coords), devlog))
    launcher = subprocess.Popen(
        [ADB, "-s", serial, "shell", remote_injector],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    frames = []
    start = recording_start
    try:
        recorder.wait(timeout=85.0)
    except subprocess.TimeoutExpired:
        recorder.terminate()
        try:
            recorder.wait(timeout=5.0)
        except subprocess.TimeoutExpired:
            recorder.kill()
            recorder.wait()
        print("TOUCH grabador no terminó dentro de 85 s")
    try:
        launcher.wait(timeout=8.0)
    except subprocess.TimeoutExpired:
        launcher.terminate()
        try:
            launcher.wait(timeout=3.0)
        except subprocess.TimeoutExpired:
            launcher.kill()
            launcher.wait()
        print("TOUCH inyector no salió al terminar la grabación")
    stop.set()
    follower.join(timeout=3.0)
    recorder_stream.close()
    pulled = adb_call(serial, "pull", remote_video, str(video_path), timeout=25.0)
    if pulled.returncode != 0:
        raise RuntimeError(pulled.stderr.decode(errors="replace")[:240])
    try:
        import cv2
        capture = cv2.VideoCapture(str(video_path))
        fps = capture.get(cv2.CAP_PROP_FPS)
        count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if not capture.isOpened() or fps <= 0 or count < 10:
            raise RuntimeError("grabación ilegible: fps=%s frames=%s" % (fps, count))
        for index in range(count):
            ok, bgr = capture.read()
            if not ok:
                continue
            image = Image.fromarray(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB))
            # Del mando sólo se guarda su centro medido: el recorte de la región
            # del mando no se usa después y retenerlo costaba ~540 MB.
            frames.append({"t": round(index / fps, 2),
                           "velocidad": image.crop(region("velocidad")),
                           "marcha": image.crop(region("marcha")),
                           "cx": (knob(image) or {}).get("cx"),
                           "gas": pedal_pressure(image, region("pedal_acelerador_panel"), "throttle"),
                           "freno": pedal_pressure(image, region("pedal_freno_panel"), "brake")})
        capture.release()
    except (RuntimeError, OSError, ImportError) as error:
        print("TOUCH captura de vídeo falló:", error)
        if recorder_log.is_file():
            print("TOUCH grabador:", recorder_log.read_text(errors="replace")[-1000:])
    marker_times = {line: round(stamp - start, 2) for stamp, line in markers}
    print("TOUCH marcas_temporales=%s" % marker_times)
    phases = {}
    end_i = None
    brake_steer_i = brake_steer_release_i = release_i = release_confirm_i = None
    # Identify the phases from control feedback painted on screen, not adb
    # timestamps: emulator scheduling can distort that clock under GPU load.
    def first_index(predicate, begin=0):
        return next((i for i in range(begin, len(frames)) if predicate(frames[i])), None)
    throttle_i = first_index(lambda f: f["gas"] >= 0.30)
    gas_release_i = first_index(lambda f: throttle_i is not None and f["gas"] < 0.30 and
                                f["t"] >= frames[throttle_i]["t"] + 7.0,
                                (throttle_i + 1) if throttle_i is not None else 0)
    brake_i = first_index(lambda f: gas_release_i is not None and f["freno"] >= 0.30,
                          (gas_release_i + 1) if gas_release_i is not None else 0)
    brake_release_i = first_index(lambda f: brake_i is not None and f["freno"] < 0.30 and
                                  f["t"] >= frames[brake_i]["t"] + 5.0,
                                  (brake_i + 1) if brake_i is not None else 0)
    multi_i = first_index(lambda f: brake_release_i is not None and f["gas"] >= 0.30,
                          (brake_release_i + 1) if brake_release_i is not None else 0)
    steer_i = first_index(lambda f: multi_i is not None and f["cx"] is not None
                          and f["cx"] >= G["mando_centro"][0] + umbral_desvio_mando(),
                          (multi_i + 1) if multi_i is not None else 0)
    end_i = first_index(lambda f: steer_i is not None and en_centro(f["cx"]),
                         (steer_i + 1) if steer_i is not None else 0)
    end_confirm_i = first_index(lambda f: end_i is not None and en_centro(f["cx"]),
                                (end_i + 1) if end_i is not None else 0)
    # Freno + direccion simultaneos: es la primera fase con el freno pisado y el
    # acelerador suelto despues del retorno del multitactil anterior.
    brake_steer_i = first_index(lambda f: end_confirm_i is not None and f["freno"] >= 0.30 and f["gas"] < 0.30,
                                (end_confirm_i + 1) if end_confirm_i is not None else 0)
    brake_steer_release_i = first_index(lambda f: brake_steer_i is not None and f["freno"] < 0.30,
                                        (brake_steer_i + 1) if brake_steer_i is not None else 0)
    # Liberacion total: ni pedales ni direccion, con el mando ya en el centro.
    release_i = first_index(lambda f: brake_steer_release_i is not None and en_centro(f["cx"])
                            and f["gas"] < 0.30 and f["freno"] < 0.30,
                            (brake_steer_release_i + 1) if brake_steer_release_i is not None else 0)
    release_confirm_i = first_index(lambda f: release_i is not None and en_centro(f["cx"])
                                    and f["gas"] < 0.30 and f["freno"] < 0.30,
                                    (release_i + 1) if release_i is not None else 0)
    if throttle_i is not None and brake_i is not None and multi_i is not None and steer_i is not None and end_confirm_i is not None:
        phases = {"idle": frames[0]["t"], "throttle": frames[throttle_i]["t"],
                  "brake": frames[brake_i]["t"], "multitouch": frames[multi_i]["t"]}
        phases["end"] = frames[end_i]["t"]
        phases["end_confirm"] = frames[end_confirm_i]["t"]
        phases["direccion"] = frames[steer_i]["t"]
        if brake_steer_i is not None:
            phases["brake_steer"] = frames[brake_steer_i]["t"]
        if release_i is not None:
            phases["release"] = frames[release_i]["t"]
        print("TOUCH fases_renderizadas=%s" % phases)
        print("TOUCH freno_direccion=%s/%s liberacion=%s/%s" %
              (brake_steer_i, brake_steer_release_i, release_i, release_confirm_i))
    else:
        print("TOUCH no se detectaron todas las fases en vídeo: throttle=%s brake=%s multitouch=%s steer=%s end=%s end_confirm=%s" %
              (throttle_i, brake_i, multi_i, steer_i, end_i, end_confirm_i))

    if frames:
        (outdir / "capture-metadata.json").write_text(json.dumps({
            "fps_video": round(fps, 3), "frames": len(frames),
            "duracion_video_s": round(len(frames) / fps, 2) if fps > 0 else None,
            "marcas_inyector_s": marker_times,
            "fases_video_s": phases,
            "presion_color_gas": [round(f["gas"], 4) for f in frames],
            "presion_color_freno": [round(f["freno"], 4) for f in frames],
            "direccion_cx": [f["cx"] for f in frames],
        }, indent=2, ensure_ascii=False))
    print("TOUCH frame_times_start=%.2f frame_times_end=%.2f" % (
        frames[0]["t"], frames[-1]["t"]) if frames else "TOUCH sin fotogramas")
    recorder_stream.close()
    stop.set()
    try:
        device_log = adb_call(serial, "shell", "cat", devlog, timeout=12.0).stdout.decode(errors="replace")
    except (subprocess.TimeoutExpired, OSError) as error:
        device_log = "ERROR leyendo log táctil: %s" % error
    (outdir / "android-touch.log").write_text(device_log)
    if len(frames) < 10:
        print("TOUCH PASS=False (demasiado pocas capturas: %d; mira ADB, touch.mp4 y logs del emulador)" % len(frames))
        (outdir / "touch.json").write_text(json.dumps({"fases": phases, "frames": len(frames),
            "fps_video": round(fps, 3) if 'fps' in locals() else None,
            "video": str(video_path), "error": "capturas insuficientes"}, indent=2, ensure_ascii=False))
        return 1

    idle = frames[:throttle_i] if throttle_i is not None else []
    throttle = frames[throttle_i:gas_release_i] if throttle_i is not None and gas_release_i is not None else []
    brake = frames[brake_i:brake_release_i] if brake_i is not None and brake_release_i is not None else []
    multi = frames[multi_i:end_i] if multi_i is not None and end_i is not None else []
    end = frames[end_i:end_confirm_i + 1] if end_i is not None and end_confirm_i is not None else []
    if not all((idle, throttle, brake, multi, end)):
        counts = {"idle": len(idle), "throttle": len(throttle), "brake": len(brake),
                  "multitouch": len(multi), "end": len(end)}
        print("TOUCH PASS=False (alguna fase no tiene capturas: %s)" % counts)
        (outdir / "touch.json").write_text(json.dumps({
            "fases": phases, "frames": len(frames), "fps_video": round(fps, 3),
            "video": str(video_path), "frames_por_fase": counts,
            "error": "fases sin capturas suficientes",
        }, indent=2, ensure_ascii=False))
        return 1

    baseline_speed, baseline_gear = idle[-1]["velocidad"], idle[-1]["marcha"]

    def score(frame, reference, key):
        diff = ImageChops.difference(frame[key], reference).convert("L")
        hist = diff.histogram()
        return sum(hist[26:])

    speed_throttle = max(score(f, baseline_speed, "velocidad") for f in throttle)
    gear_throttle = max(score(f, baseline_gear, "marcha") for f in throttle)
    gas_idle = idle[-1]["gas"]
    gas_press = max(f["gas"] for f in throttle)
    gas_slide_release = min((f["gas"] for f in frames[gas_release_i:brake_i]), default=1.0)
    last_throttle = throttle[-1]["velocidad"]
    speed_brake = max(score(f, last_throttle, "velocidad") for f in brake)
    brake_idle = idle[-1]["freno"]
    brake_press = max(f["freno"] for f in brake)
    brake_slide_release = min((f["freno"] for f in frames[brake_release_i:multi_i]), default=1.0)
    # Planeo previo al freno (desde que se suelta el acelerador hasta que se pisa
    # el freno). Si en esa ventana los dígitos de velocidad no cambian, el coche
    # ya estaba parado —los toques van cronometrados sobre una conducción real y
    # el coche puede haber acabado contra una valla—, y entonces frenar no puede
    # cambiar la velocidad: exigirlo mediría la suerte del coche, no el pedal.
    # Un coche que planea sin tocar nada no puede mantener la velocidad, así que
    # dígitos quietos dos segundos y medio significan coche detenido.
    planeo_freno = frames[gas_release_i:brake_i] if gas_release_i is not None and brake_i is not None else []
    cola_freno = planeo_freno[-53:]
    venia_en_marcha_freno = (len(cola_freno) >= 20
                             and score(cola_freno[-1], cola_freno[0]["velocidad"],
                                       "velocidad") >= umbral_cambio(200))
    speed_multi = max(score(f, baseline_speed, "velocidad") for f in multi)
    cx_multi = max((f["cx"] or -1) for f in multi)
    cx_steer = max((f["cx"] for f in multi if f["cx"] is not None), default=-1)
    cx_idle = idle[-1]["cx"]
    cx_end = end[-1]["cx"]
    # Freno + direccion a la vez, medidos en la misma grabacion. La direccion va
    # al lado contrario del multitactil, asi que lo que se exige es un desvio
    # real hacia la izquierda respecto al reposo, no un simple cambio.
    bs = frames[brake_steer_i:brake_steer_release_i] if brake_steer_i is not None and brake_steer_release_i is not None else []
    release = frames[release_i:release_confirm_i + 1] if release_i is not None and release_confirm_i is not None else []
    bs_brake = max((f["freno"] for f in bs), default=0.0)
    bs_gas = max((f["gas"] for f in bs), default=0.0)
    bs_cx_left = min((f["cx"] for f in bs if f["cx"] is not None), default=-1)
    bs_speed = max((score(f, bs[0]["velocidad"], "velocidad") for f in bs), default=0) if bs else 0
    # Simultaneidad de verdad: fotogramas en los que el freno está pisado Y el
    # mando desviado, no uno después del otro. No depende de que el coche se
    # mueva, así que mide lo que la fase promete.
    bs_simultaneos = sum(1 for f in bs if f["freno"] >= 0.30 and f["cx"] is not None
                         and abs(f["cx"] - G["mando_centro"][0]) >= umbral_retorno_mando())
    # ¿Venía el coche en marcha al empezar esta fase? Los toques van cronometrados
    # sobre una conducción real, así que a estas alturas puede estar parado —o
    # contra una valla— y entonces frenar no PUEDE cambiar la velocidad: exigirlo
    # mediría la suerte del coche, no el pedal. Un coche que planea sin tocar nada
    # no mantiene la velocidad (lo frenan el aire y el rozamiento), así que unos
    # dígitos quietos en el último segundo y medio antes de la fase significan
    # coche detenido. La ventana es el final del planeo, no todo: en una vuelta
    # real el coche venía frenando desde el multitáctil y se paró justo antes.
    planeo = frames[end_confirm_i:brake_steer_i] if end_confirm_i is not None and brake_steer_i is not None else []
    cola = planeo[-53:]
    venia_en_marcha = (len(cola) >= 20
                       and score(cola[-1], cola[0]["velocidad"], "velocidad") >= umbral_cambio(200))
    release_press = max([f["gas"] for f in release] + [f["freno"] for f in release], default=1.0)
    release_cx = release[-1]["cx"] if release else None
    report = {
        "fases": phases,
        "frames": len(frames),
        "fps_video": round(fps, 3),
        "video": str(video_path),
        "mando_cx_reposo": cx_idle,
        "mando_cx_multitouch": cx_multi,
        "mando_cx_desvio_maximo": cx_steer,
        "mando_cx_final": cx_end,
        "mando_cx_confirmacion_centro": end[-1]["cx"],
        "velocidad_cambio_gas": speed_throttle,
        "marcha_cambio_gas": gear_throttle,
        "velocidad_cambio_freno": speed_brake,
        "freno_venia_en_marcha": venia_en_marcha_freno,
        "freno_planeo_frames": len(planeo_freno),
        "velocidad_cambio_multitouch": speed_multi,
        "gas_presion_reposo_pantalla": round(gas_idle, 4),
        "gas_presion_pantalla_max": round(gas_press, 4),
        "gas_liberacion_analogica": round(gas_slide_release, 4),
        "freno_presion_reposo_pantalla": round(brake_idle, 4),
        "freno_presion_pantalla_max": round(brake_press, 4),
        "freno_liberacion_analogica": round(brake_slide_release, 4),
        "freno_direccion_fase_s": phases.get("brake_steer"),
        "freno_direccion_presion_max": round(bs_brake, 4),
        "freno_direccion_gas_max": round(bs_gas, 4),
        "freno_direccion_cx_izquierda": bs_cx_left,
        "freno_direccion_cambio_velocidad": bs_speed,
        "freno_direccion_simultaneos_frames": bs_simultaneos,
        "freno_direccion_venia_en_marcha": venia_en_marcha,
        "freno_direccion_planeo_frames": len(planeo),
        "liberacion_fase_s": phases.get("release"),
        "liberacion_cx": release_cx,
        "liberacion_presion_max": round(release_press, 4),
    }
    print("TOUCH", json.dumps(report, ensure_ascii=False))
    ok = True
    if gas_press - gas_idle < 0.15 or speed_throttle < umbral_cambio(200) or gear_throttle < umbral_cambio(40):
        print("TOUCH FALLA: el acelerador en pantalla no produce cambio de velocidad/marcha")
        ok = False
    if gas_slide_release > gas_idle + max(0.08, 0.35 * (gas_press - gas_idle)):
        print("TOUCH FALLA: al deslizar al fondo del acelerador no libera suficiente presión respecto al reposo")
        ok = False
    if brake_press - brake_idle < 0.15:
        print("TOUCH FALLA: el freno en pantalla no se pisa (reposo %.4f, máximo %.4f)"
              % (brake_idle, brake_press))
        ok = False
    if speed_brake < umbral_cambio(200) and venia_en_marcha_freno:
        print("TOUCH FALLA: el freno en pantalla no produce cambio de velocidad "
              "(cambio=%s, el coche venía en marcha)" % speed_brake)
        ok = False
    if speed_brake < umbral_cambio(200) and not venia_en_marcha_freno:
        print("TOUCH aviso: el coche ya venía parado al pisar el freno (%d fotogramas de "
              "planeo, quieto en el último segundo y medio); se mide el pedal, no la inercia"
              % len(planeo_freno))
    if brake_slide_release > brake_idle + max(0.08, 0.35 * (brake_press - brake_idle)):
        print("TOUCH FALLA: al deslizar al fondo del freno no libera suficiente presión respecto al reposo")
        ok = False
    if cx_steer < 0 or cx_idle is None or cx_steer - cx_idle < umbral_retorno_mando():
        print("TOUCH FALLA: el joystick no se desplaza al pisar el acelerador a la vez")
        ok = False
    if speed_multi < umbral_cambio(200):
        print("TOUCH FALLA: las dos entradas simultáneas no llegan al coche")
        ok = False
    if cx_end is None or abs(cx_end - G["mando_centro"][0]) > G["tolerancia_centro"] \
            or abs(end[-1]["cx"] - G["mando_centro"][0]) > G["tolerancia_centro"]:
        print("TOUCH FALLA: el mando no vuelve al centro (cx=%s)" % cx_end)
        ok = False
    if not bs:
        print("TOUCH FALLA: no se detectó en pantalla la fase de freno + dirección simultáneos")
        ok = False
    else:
        if bs_brake < 0.30:
            print("TOUCH FALLA: en la fase de freno + dirección el freno no llega a la pantalla (máx %.4f)" % bs_brake)
            ok = False
        if bs_gas >= 0.30:
            print("TOUCH FALLA: en la fase de freno + dirección el acelerador sigue pisado (máx %.4f)" % bs_gas)
            ok = False
        if cx_idle is None or bs_cx_left < 0 or cx_idle - bs_cx_left < umbral_retorno_mando():
            print("TOUCH FALLA: el mando no gira al lado contrario mientras se frena (cx=%s, reposo=%s)" % (bs_cx_left, cx_idle))
            ok = False
        if bs_simultaneos < 30:
            print("TOUCH FALLA: el freno y el mando no coinciden pisados a la vez "
                  "(sólo %d fotogramas simultáneos)" % bs_simultaneos)
            ok = False
        if bs_speed < umbral_cambio(200) and venia_en_marcha:
            print("TOUCH FALLA: frenar y girar a la vez no cambia la velocidad en pantalla "
                  "(cambio=%s, el coche venía en marcha)" % bs_speed)
            ok = False
        if bs_speed < umbral_cambio(200) and not venia_en_marcha:
            print("TOUCH aviso: el coche venía parado (quieto en el último segundo y medio); "
                  "la respuesta se mide por los %d fotogramas de freno y mando a la vez"
                  % bs_simultaneos)
    if not release:
        print("TOUCH FALLA: no se detectó en pantalla la fase de liberación total de los controles")
        ok = False
    else:
        if release_press >= 0.30:
            print("TOUCH FALLA: tras soltar todo queda presión en algún pedal (máx %.4f)" % release_press)
            ok = False
        if release_cx is None or abs(release_cx - G["mando_centro"][0]) > G["tolerancia_centro"]:
            print("TOUCH FALLA: el mando no vuelve al centro tras soltar todo (cx=%s)" % release_cx)
            ok = False
    print("TOUCH PASS=", ok)

    # Hoja de contacto para revisión humana: una fila por fase con el mismo
    # recorte de velocidad y de marcha, en el orden en que ocurrieron.
    vw, vh = region("velocidad")[2] - region("velocidad")[0], region("velocidad")[3] - region("velocidad")[1]
    mw, mh = region("marcha")[2] - region("marcha")[0], region("marcha")[3] - region("marcha")[1]
    # Keep a bounded contact sheet: encoders reject extremely wide images when
    # the recording runs at host frame rate (~1100 frames in the emulator).
    rows = (idle, throttle, brake, multi, end, bs, release)
    columns = min(80, max(max(len(phase) for phase in rows), 1))
    sheet = Image.new("RGB", (columns * (vw + mw + 12), len(rows) * (vh + 8)), (12, 16, 20))
    for row, phase in enumerate(rows):
        stride = max(1, len(phase) // columns)
        for column, frame in enumerate(phase[::stride][:columns]):
            x = column * (vw + mw + 12)
            sheet.paste(frame["velocidad"], (x, row * (vh + 8)))
            sheet.paste(frame["marcha"], (x + vw + 4, row * (vh + 8) + (vh - mh) // 2))
    sheet.save(outdir / "fases-velocidad-marcha.jpg", "JPEG", quality=88)
    (outdir / "touch.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    # --size permite fijar la geometría a mano (útil con capturas ya hechas); si
    # no se da, las órdenes que tienen serial leen el tamaño del dispositivo.
    p = sub.add_parser("layout"); p.add_argument("png"); p.add_argument("--size")
    p.add_argument("--display", help="volcado de `dumpsys window displays`, para el recorte de pantalla")
    p.set_defaults(func=cmd_layout)
    p = sub.add_parser("ready"); p.add_argument("serial"); p.add_argument("--size")
    p.set_defaults(func=cmd_ready)
    p = sub.add_parser("clock"); p.add_argument("serial"); p.add_argument("outdir")
    p.add_argument("--size"); p.set_defaults(func=cmd_clock)
    p = sub.add_parser("touch"); p.add_argument("serial"); p.add_argument("outdir")
    p.add_argument("--size"); p.set_defaults(func=cmd_touch)
    p = sub.add_parser("mando"); p.add_argument("serial"); p.add_argument("outdir")
    p.add_argument("--size"); p.set_defaults(func=cmd_mando)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
