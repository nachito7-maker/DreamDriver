#!/usr/bin/env python3
"""Validación en el aparato de la cámara de morro nueva y del rendimiento.

Qué hace, con toques REALES del sistema (nada de llamar al juego por dentro):

  1. Relanza la app instalada y comprueba que la huella instalada es la del APK
     que se acaba de compilar (se pasa con --sha).
  2. Acelera con `input swipe` sobre el pedal y captura la persecución.
  3. Pisa el botón de vista hasta que la vista CAMBIA (se comprueba midiendo el
     coche, no el botón), captura el morro EN MARCHA y otra vez con el pedal
     pisado.
  4. Vuelve a la persecución y captura.
  5. Mide en píxeles la composición con LA MISMA REGLA DECLARADA con la que se
     mide la referencia aprobada en `.tools/recovery/fase-fp/morro_pixeles.py`:
     librea azul + neumático negro neutro, sólo manchas que tocan el borde
     inferior del cuadro (el coche entra por el borde: la cámara va dentro).
     De ahí salen la franja que ocupa el coche y cuánto se ve de cada neumático.
  6. Mide el movimiento comparando dos capturas separadas 0,35 s (no depende de
     leer el HUD) y lee la velocidad de la barra cuando se puede.
  7. Mide fotogramas con `dumpsys SurfaceFlinger --timestats` durante 3 s en cada
     vista y recoge el logcat de la app.

Criterios:
  * neumático delantero visible en el morro: ≥ 0,5 % del lienzo (TIRE_MIN_PX del
    proyecto) y con su borde superior por debajo del 45 % del alto.
  * el coche ocupa la franja inferior: franja ≥ 0,25 del alto.
  * en persecución el coche NO toca el borde inferior (franja < 0,10).
  * el coche se mueve entre las dos capturas de la misma vista (≥ 1 % de píxeles
    cambiados) y el cronómetro avanza alrededor del cambio.
  * sin líneas de error de material/textura/shader en el logcat de la app.

Uso: validar_morro_dispositivo.py <serial> <dir-salida> --sha <sha256 del APK>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import threading
import time
from pathlib import Path

from PIL import Image

RECUPERACION = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RECUPERACION))
sys.path.insert(0, str(RECUPERACION / "fase-camara"))
import numpy as np                    # noqa: E402
from scipy import ndimage             # noqa: E402

import screen_check as sc             # noqa: E402
import screen_geometry                # noqa: E402
import camera_pixels as cp            # noqa: E402
import capturar_dispositivo as cd     # noqa: E402

PKG = "com.freebuff.f1oneshot.barcelonamoto"

TIRE_MIN_FRACTION = 0.005     # TIRE_MIN_PX del proyecto
TIRE_TOP_MAX = 0.45           # el neumático no sube del 45 % del alto
NOSE_BAND_MIN = 0.25
CHASE_BAND_MAX = 0.10
MOTION_MIN = 0.01
CLOCK_CAMBIO_MIN = 300

# Misma regla que `morro_pixeles.py` para medir la referencia aprobada.
REF_LIBREA_B_R_MIN = 18
REF_LIBREA_LUM_MAX = 120.0
REF_NEUMATICO_LUM_MAX = 58.0
REF_NEUMATICO_SAT_MAX = 0.22
AZUL = 0


def huella_instalada(serial: str) -> str:
    salida = sc.adb_call(serial, "shell", "pm", "path", PKG, timeout=15.0).stdout.decode().strip()
    ruta = salida.splitlines()[0].replace("package:", "") if salida else ""
    if not ruta:
        return ""
    local = Path("/tmp/f1-instalado.apk")
    sc.adb_call(serial, "pull", ruta, str(local), timeout=180.0)
    return hashlib.sha256(local.read_bytes()).hexdigest() if local.exists() else ""


def _componentes(mascara: np.ndarray) -> np.ndarray:
    """Sólo las manchas que tocan el borde inferior (el coche entra por abajo)."""
    etiquetas, cuantas = ndimage.label(mascara)
    if cuantas == 0:
        return mascara
    borde = set(np.unique(etiquetas[-1]).tolist()) - {0}
    tamanos = ndimage.sum(mascara, etiquetas, range(1, cuantas + 1))
    mayor = float(tamanos.max())
    quedan = [i + 1 for i, tamano in enumerate(tamanos)
              if i + 1 in borde and tamano >= max(400, mayor * 0.05)]
    return np.isin(etiquetas, quedan)


def _medida(mascara: np.ndarray) -> dict:
    alto, ancho = mascara.shape
    ys, xs = np.nonzero(mascara)
    if len(xs) == 0:
        return {"pixeles": 0, "fraccion": 0.0, "y0": 1.0, "centro_x": 0.5}
    return {
        "pixeles": int(len(xs)),
        "fraccion": round(len(xs) / (alto * ancho), 5),
        "y0": round(float(ys.min()) / alto, 4),
        "centro_x": round(float((xs.min() + xs.max()) / 2) / ancho, 4),
    }


def _rueda_en_esquina(imagen: np.ndarray, luma: np.ndarray, fx0: float, fx1: float) -> dict:
    """Neumático en una esquina inferior: negro que toca el borde de abajo.

    La regla de saturación de la referencia no sirve en el aparato: el neumático
    casi negro (luma ~15) refleja el cielo y su saturación aparente sube a 0,6,
    aunque sea negro. Aquí la condición es la que distingue de verdad: muy oscuro
    (luma < 45), dentro de la caja de la esquina, y la mancha tiene que TOCAR el
    borde inferior del cuadro. Medido en el aparato: 3,6 % y 3,3 % del lienzo en
    el morro y 0 % en las dos persecuciones, así que separa las vistas sin
    depender del color.
    """
    alto, ancho = luma.shape
    caja = np.zeros((alto, ancho), dtype=bool)
    caja[:, int(ancho * fx0):int(ancho * fx1)] = True
    mascara = (luma < 45) & caja
    etiquetas, cuantas = ndimage.label(mascara)
    if cuantas == 0:
        return _medida(mascara)
    borde = set(np.unique(etiquetas[-1]).tolist()) - {0}
    tamanos = ndimage.sum(mascara, etiquetas, range(1, cuantas + 1))
    quedan = [i + 1 for i, tamano in enumerate(tamanos) if i + 1 in borde and tamano >= 400]
    return _medida(np.isin(etiquetas, quedan))


def medir(png: Path) -> dict:
    imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    alto, ancho = imagen.shape[:2]
    rojo, azul_ = imagen[:, :, 0], imagen[:, :, 2]
    luma = imagen.mean(axis=2)
    # Los mandos y el mando de dirección viven en los extremos: se recorta el 15 %
    # de cada lado para que sus paneles no entren en la máscara de la librea.
    recorte = np.zeros((alto, ancho), dtype=bool)
    recorte[:, int(ancho * 0.15):int(ancho * 0.85)] = True
    saturacion = (imagen.max(axis=2) - imagen.min(axis=2)) / np.maximum(imagen.max(axis=2), 1)
    librea = ((azul_ - rojo) >= REF_LIBREA_B_R_MIN) & (luma < REF_LIBREA_LUM_MAX)
    neumaticos = (luma < REF_NEUMATICO_LUM_MAX) & (saturacion < REF_NEUMATICO_SAT_MAX)
    coche = _componentes((librea | neumaticos) & recorte)
    coche_m = _medida(coche)
    return {
        "franja": round(1.0 - coche_m["y0"], 3) if coche_m["pixeles"] else 0.0,
        "centro_x": coche_m["centro_x"],
        "coche_fraccion": coche_m["fraccion"],
        "neumatico_izquierdo": _rueda_en_esquina(imagen, luma, 0.18, 0.40),
        "neumatico_derecho": _rueda_en_esquina(imagen, luma, 0.60, 0.82),
    }


def barra_velocidad(png: Path) -> float | None:
    """Velocidad del HUD con la misma barra y color que `camera_pixels`.

    En el aparato la barra arranca unos píxeles más a la derecha que en el
    lienzo de 2400 del anfitrión (el panel se ancla al borde físico), así que se
    toma el borde izquierdo REAL del relleno dentro de la banda y se mide su
    largo: el ancho de la barra sigue siendo el del diseño.
    """
    imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    alto, ancho = imagen.shape[:2]
    escala = min(max(alto / 900.0, 0.68), 1.32)
    x_ini = int(round((cp.BARRA["panel"][0] + cp.BARRA["pos"][0]) * escala))
    ancho_barra = cp.BARRA["tam"][0] * escala
    y0 = max(0, int(round((cp.BARRA["panel"][1] + cp.BARRA["pos"][1]) * escala)) - 3)
    y1 = min(alto, y0 + int(round(cp.BARRA["tam"][1] * escala)) + 8)
    x1 = min(ancho, int(round(x_ini + ancho_barra + 30)))
    banda = imagen[y0:y1, max(0, x_ini - 30):x1, :]
    coincide = np.abs(banda - np.array(cp.RELLENO)).sum(axis=2) < 45
    relleno = 0
    for fila in coincide:
        arranques = np.nonzero(fila)[0]
        if len(arranques) == 0:
            continue
        inicio = int(arranques[0])
        largo = 0
        while inicio + largo < fila.shape[0] and fila[inicio + largo]:
            largo += 1
        relleno = max(relleno, largo)
    return round(relleno / ancho_barra * cp.BARRA["max_kmh"], 1)


def diferencia(a: Path, b: Path) -> float:
    uno = np.asarray(Image.open(a).convert("RGB")).astype(np.int16)
    otro = np.asarray(Image.open(b).convert("RGB")).astype(np.int16)
    return round(float((np.abs(uno - otro).max(axis=2) > 14).mean()), 4)


def fotogramas(serial: str, segundos: float = 3.0) -> dict:
    sc.adb_call(serial, "shell", "dumpsys", "SurfaceFlinger", "--timestats", "-enable", timeout=20.0)
    sc.adb_call(serial, "shell", "dumpsys", "SurfaceFlinger", "--timestats", "-clear", timeout=20.0)
    time.sleep(segundos)
    salida = sc.adb_call(serial, "shell", "dumpsys", "SurfaceFlinger", "--timestats", "-dump",
                         timeout=30.0).stdout.decode(errors="replace")
    fps = None
    fotogramas_totales = None
    for linea in salida.splitlines():
        if "averageFPS" in linea and fps is None:
            try:
                fps = float(linea.split("=")[-1])
            except ValueError:
                pass
        if "totalFrames" in linea and fotogramas_totales is None:
            try:
                fotogramas_totales = int(linea.split("=")[-1])
            except ValueError:
                pass
    if fps is None:
        return {"error": "sin estadísticas de fotogramas", "segundos": segundos}
    return {"fps": round(fps, 1), "fotogramas": fotogramas_totales, "segundos": segundos}


def errores_logcat(serial: str) -> list:
    salida = sc.adb_call(serial, "shell", "logcat", "-d", "-t", "600", timeout=25.0)
    patrones = re.compile(r"(SCRIPT ERROR|ERROR:|shader|texture|material|GL_INVALID)", re.I)
    lineas = [l.strip() for l in salida.stdout.decode(errors="replace").splitlines()
              if PKG in l or "godot" in l.lower()]
    return [l for l in lineas if patrones.search(l)][:12]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("serial")
    parser.add_argument("outdir")
    parser.add_argument("--sha", default=None, help="SHA-256 del APK que se acaba de compilar")
    args = parser.parse_args()
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    ancho, alto = screen_geometry.pantalla_de(serial)
    sc.usar_geometria(ancho, alto)
    datos = {"lienzo": [ancho, alto]}
    errores = []

    if args.sha:
        instalada = huella_instalada(serial)
        datos["sha_instalado"] = instalada
        datos["sha_apk"] = args.sha
        print("DISPOSITIVO huella instalada=%s apk=%s" % (instalada[:16], args.sha[:16]))
        if instalada != args.sha:
            errores.append("la huella instalada no es la del APK compilado (%s frente a %s)"
                           % (instalada[:16], args.sha[:16]))

    print("DISPOSITIVO relanzando %s" % serial)
    cd.relanzar(serial)

    def acelerar(veces: int, ms: int, segundos: float) -> None:
        for _ in range(veces):
            cd.exigir_nuestro(serial, "la conducción")
            hilo = threading.Thread(target=cd.pisotear, args=(serial, "pedal_acelerador", ms), daemon=True)
            hilo.start()
            time.sleep(segundos)

    def capturar(nombre: str) -> Path:
        png = outdir / nombre
        sc.screencap(serial).save(png)
        return png

    x0, y0, x1, y1 = sc.region("camara_boton")
    bx, by = (x0 + x1) // 2, (y0 + y1) // 2

    def cambiar_vista(esperando_morro: bool) -> int:
        """Pisa el botón hasta que la vista cambia de verdad (se mide el coche)."""
        for intento in range(1, 4):
            sc.adb_call(serial, "shell", "input", "tap", str(bx), str(by), timeout=15.0)
            time.sleep(1.5)
            prueba = capturar("sonda-vista-%d.png" % intento)
            fila = medir(prueba)
            en_morro = fila["franja"] >= NOSE_BAND_MIN
            print("DISPOSITIVO toque %d en (%d,%d): franja=%.3f morro=%s"
                  % (intento, bx, by, fila["franja"], en_morro))
            if en_morro == esperando_morro:
                return intento
        return 0

    acelerar(3, 1200, 0.7)
    p1 = capturar("dispositivo-persecucion-1.png")
    p1b = capturar("dispositivo-persecucion-1-movimiento.png")
    reloj1 = sc.screencap(serial)

    intentos = cambiar_vista(True)
    datos["toques_hasta_morro"] = intentos
    print("DISPOSITIVO vista del morro tras %d toque(s) del botón" % intentos)
    p2 = capturar("dispositivo-morro.png")
    p2b = capturar("dispositivo-morro-movimiento.png")

    # Con el pedal pisado: lo que se ve al acelerar en la vista nueva.
    hilo = threading.Thread(target=cd.pisotear, args=(serial, "pedal_acelerador", 2000), daemon=True)
    hilo.start()
    time.sleep(1.0)
    p4 = capturar("dispositivo-morro-pedal.png")
    datos["fps_morro"] = fotogramas(serial, 2.5)
    hilo.join(timeout=12.0)

    intentos = cambiar_vista(False)
    datos["toques_hasta_persecucion"] = intentos
    p5 = capturar("dispositivo-persecucion-2.png")
    p5b = capturar("dispositivo-persecucion-2-movimiento.png")
    datos["fps_persecucion"] = fotogramas(serial, 2.5)
    reloj2 = sc.screencap(serial)

    for etiqueta, png in (("persecucion-1", p1), ("morro", p2), ("morro-pedal", p4),
                          ("persecucion-2", p5)):
        datos[etiqueta] = medir(png)
        datos[etiqueta]["kmh"] = barra_velocidad(png)
        fila = datos[etiqueta]
        print("DISPOSITIVO %-14s kmh=%-6s franja=%.3f centro=%.2f neumáticos izq=%.2f%% (y0=%.2f) der=%.2f%% (y0=%.2f)"
              % (etiqueta, fila["kmh"], fila["franja"], fila["centro_x"],
                 fila["neumatico_izquierdo"]["fraccion"] * 100, fila["neumatico_izquierdo"]["y0"],
                 fila["neumatico_derecho"]["fraccion"] * 100, fila["neumatico_derecho"]["y0"]))

    datos["movimiento_persecucion"] = diferencia(p1, p1b)
    datos["movimiento_morro"] = diferencia(p2, p2b)
    datos["movimiento_persecucion_2"] = diferencia(p5, p5b)
    print("DISPOSITIVO movimiento: persecución=%.3f morro=%.3f vuelta=%.3f"
          % (datos["movimiento_persecucion"], datos["movimiento_morro"], datos["movimiento_persecucion_2"]))

    print("DISPOSITIVO rendimiento morro=%s persecución=%s"
          % (datos["fps_morro"], datos["fps_persecucion"]))
    datos["logcat"] = errores_logcat(serial)
    print("DISPOSITIVO logcat sospechoso=%d" % len(datos["logcat"]))
    for linea in datos["logcat"]:
        print("  LOG %s" % linea)

    for etiqueta in ("morro", "morro-pedal"):
        fila = datos[etiqueta]
        for lado, llave in (("izq", "neumatico_izquierdo"), ("der", "neumatico_derecho")):
            rueda = fila[llave]
            if rueda["fraccion"] < TIRE_MIN_FRACTION:
                errores.append("%s: no se ve el neumático %s (%.2f %% del lienzo, se pide ≥ %.1f %%)"
                               % (etiqueta, lado, rueda["fraccion"] * 100, TIRE_MIN_FRACTION * 100))
            if rueda["y0"] < TIRE_TOP_MAX:
                errores.append("%s: el neumático %s sube hasta el %.0f %% del alto (se pide ≥ %.0f %%)"
                               % (etiqueta, lado, rueda["y0"] * 100, TIRE_TOP_MAX * 100))
        if fila["franja"] < NOSE_BAND_MIN:
            errores.append("%s: el coche sólo ocupa la franja inferior %.2f (se pide ≥ %.2f)"
                           % (etiqueta, fila["franja"], NOSE_BAND_MIN))
        if abs(fila["centro_x"] - 0.5) > 0.12:
            errores.append("%s: el coche no está centrado (x = %.2f)" % (etiqueta, fila["centro_x"]))

    for etiqueta in ("persecucion-1", "persecucion-2"):
        fila = datos[etiqueta]
        if fila["franja"] > CHASE_BAND_MAX:
            errores.append("%s: el coche ocupa la franja inferior %.2f: no es la vista de persecución"
                           % (etiqueta, fila["franja"]))

    for etiqueta, valor in (("persecución", datos["movimiento_persecucion"]),
                            ("morro", datos["movimiento_morro"]),
                            ("vuelta", datos["movimiento_persecucion_2"])):
        if valor < MOTION_MIN:
            errores.append("%s: dos capturas separadas 0,35 s cambian sólo un %.1f %% (el coche no se mueve)"
                           % (etiqueta, valor * 100))

    reloj = sc.differences(reloj1, reloj2, sc.region("cronometro"))
    datos["cronometro"] = reloj
    print("DISPOSITIVO cronómetro %s" % reloj)
    if not (reloj["cambiados"] > CLOCK_CAMBIO_MIN and reloj["delta_max"] > 40):
        errores.append("el cronómetro no avanzó alrededor del cambio (%s)" % reloj)

    if datos["logcat"]:
        errores.append("el logcat de la app trae %d líneas de error de material/textura/shader"
                       % len(datos["logcat"]))

    datos["errores"] = errores
    datos["passed"] = not errores
    (outdir / "dispositivo-validacion.json").write_text(json.dumps(datos, indent=2, ensure_ascii=False))
    for error in errores:
        print("  ERROR %s" % error)
    print("DISPOSITIVO validación errores=%d PASS=%s" % (len(errores), not errores))
    return 0 if not errores else 1


if __name__ == "__main__":
    raise SystemExit(main())
