#!/usr/bin/env python3
"""Auditoría MEDIDA de los vídeos de conducción (9879.mp4 y 9880.mp4).

Los vídeos no se "miran": se miden. De cada fotograma se lee lo que el HUD
publica y lo que el dedo del jugador está pidiendo, con las mismas herramientas
que ya usa `verify.sh` para el dispositivo:

* **velocidad** — la barra de telemetría (relleno #58ddad sobre 360 km/h), con la
  aritmética exacta de `camera_pixels.velocidad_de_barra`.
* **dirección** — el centro del mando, medido por su raya vertical
  (`screen_check.knob`, que ya sabe leer el croma submuestreado del vídeo H.264).
* **acelerador y freno** — el relleno de cada panel (`screen_check.pedal_pressure`).

Las tres medidas se **verifican contra las funciones de referencia** del proyecto
sobre fotogramas sueltos antes de usarse en serie: si la copia rápida en numpy no
da el mismo número que la función original, el script se detiene en vez de
publicar una traza distinta a la que mide el resto de la entrega.

Salida:
    .tools/recovery/fase-muros/videos/<nombre>.json    traza completa + sucesos
    .tools/recovery/fase-muros/videos/<nombre>.csv     la traza en columnas

Uso:
    python3 .tools/recovery/fase-muros/video_audit.py ~/Downloads/9879.mp4 ...
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / ".tools" / "recovery"))

import camera_pixels as cp          # noqa: E402  (velocidad_de_barra, BARRA, RELLENO)
import screen_check as sc           # noqa: E402  (knob, pedal_pressure, geometria)

SALIDA = ROOT / ".tools" / "recovery" / "fase-muros" / "videos"
FOTOGRAMAS = ROOT / ".tools" / "recovery" / "fase-muros" / "fotogramas"

# La etiqueta de superficie del HUD (`scripts/race_hud.gd`) escribe ASPHALT,
# KERB, GRASS o GRAVEL y la tiñe con `modulate`: verde sobre asfalto, amarillo
# sobre bordillo y rojo fuera de pista. El color del texto es el del `_label`
# multiplicado por ese modulate, así que los tres colores esperables se pueden
# calcular en vez de adivinar. Sirve para una cosa concreta y muy útil: saber si
# el coche iba sobre el asfalto cuando lo pararon o si ya estaba fuera.
SUPERFICIE_BASE = (0x66, 0xD8, 0xA4)      # color del texto en `_label`
SUPERFICIE_PALETA = {
    "asfalto": (0x66, 0xD8, 0xA4),
    "borde": (0xF2, 0xC4, 0x56),
    "fuera": (0xFF, 0x71, 0x64),          # hierba o grava (mismo color)
}
SUPERFICIE_CAJA = (24.0 + 26.0, 20.0 + 112.0, 210.0, 18.0)
SUPERFICIE_TOLERANCIA = 70.0


def _color_etiqueta(modulate: tuple) -> tuple:
    return tuple(int(round(SUPERFICIE_BASE[i] * modulate[i] / 255.0)) for i in range(3))


def _superficie(rgb: np.ndarray) -> str:
    """Qué superficie informa el HUD en este fotograma, por el color del texto."""
    alto = rgb.shape[0]
    escala = min(max(alto / 900.0, 0.68), 1.32)
    x, y, ancho, alto_caja = SUPERFICIE_CAJA
    x0, y0 = int(x * escala), int(y * escala)
    recorte = rgb[y0:y0 + max(1, int(alto_caja * escala)),
                  x0:x0 + max(1, int(ancho * escala)), :].astype(np.int16)
    if recorte.size == 0:
        return "?"
    # En int16 el cuadrado se desborda y `sqrt` recibe negativos: se calcula en
    # coma flotante, que además es lo que compara distancias de color.
    recorte = recorte.astype(np.float32)
    cuentas = {}
    for nombre, modulate in SUPERFICIE_PALETA.items():
        esperado = np.array(_color_etiqueta(modulate), dtype=np.float32)
        distancia = np.sqrt(((recorte - esperado) ** 2).sum(axis=2))
        cuentas[nombre] = int((distancia < SUPERFICIE_TOLERANCIA).sum())
    ganador = max(cuentas, key=lambda k: cuentas[k])
    return ganador if cuentas[ganador] >= 12 else "?"


def _barra_kmh(rgb: np.ndarray) -> dict:
    """Velocidad en km/h leída de la barra del HUD, sobre un array RGB.

    Es la MISMA aritmética que `camera_pixels.velocidad_de_barra`, sólo que sin
    pasar por un PNG. `verificar()` comprueba que coincide número a número.
    """
    alto, ancho = rgb.shape[0], rgb.shape[1]
    escala = min(max(alto / 900.0, 0.68), 1.32)
    x_ini = int(round((cp.BARRA["panel"][0] + cp.BARRA["pos"][0]) * escala))
    ancho_barra = cp.BARRA["tam"][0] * escala
    y_arriba = (cp.BARRA["panel"][1] + cp.BARRA["pos"][1]) * escala
    y_abajo = y_arriba + cp.BARRA["tam"][1] * escala
    y0 = max(0, int(round(y_arriba)) - 3)
    y1 = min(alto, int(round(y_abajo)) + 4)
    x1 = min(ancho, int(round(x_ini + ancho_barra)) + 5)
    x0 = max(0, x_ini - 5)
    banda = rgb[y0:y1, x0:x1, :].astype(np.int16)
    coincide = np.abs(banda - cp.RELLENO).sum(axis=2) < 45
    relleno = 0
    fila_ganadora = None
    for indice_fila in range(coincide.shape[0]):
        fila = coincide[indice_fila]
        arranques = np.nonzero(fila)[0]
        for arranque in arranques:
            if not (0 <= arranque <= 9):
                continue
            resto = fila[arranque:]
            falsos = np.nonzero(~resto)[0]
            largo = int(falsos[0]) if falsos.size else int(resto.size)
            if largo > relleno:
                relleno = largo
                fila_ganadora = y0 + indice_fila
            break
    kmh = relleno / ancho_barra * cp.BARRA["max_kmh"]
    return {"kmh": round(float(kmh), 1), "relleno_px": relleno, "fila": fila_ganadora}


def _pedal_fraccion(rgb: np.ndarray, caja: tuple, cara: str) -> float:
    """Relleno del pedal, misma cuenta que `screen_check.pedal_pressure`."""
    x0, y0, x1, y1 = caja
    recorte = rgb[y0:y1, x0:x1, :].astype(np.int16)
    if recorte.size == 0:
        return 0.0
    r, g, b = recorte[:, :, 0], recorte[:, :, 1], recorte[:, :, 2]
    if cara == "throttle":
        mascara = (g - r > 80) & (g - b > 40)
    else:
        mascara = (r - g > 80) & (r - b > 40)
    return float(int(mascara.sum())) / max(1, recorte.shape[0] * recorte.shape[1])


def verificar(video: Path, indices: list, fotogramas: dict) -> list:
    """Comprueba las copias rápidas contra las funciones de referencia."""
    from PIL import Image

    fallos = []
    sc.usar_geometria(*[int(v) for v in fotogramas["tamano"]])
    with tempfile.TemporaryDirectory() as temporal:
        for indice in indices:
            rgb = fotogramas["leer"](indice)
            ruta = Path(temporal) / ("f%d.png" % indice)
            Image.fromarray(rgb).save(ruta)
            rapida = _barra_kmh(rgb)
            lenta = cp.velocidad_de_barra(ruta)
            if abs(float(lenta["kmh"]) - float(rapida["kmh"])) > 0.05:
                fallos.append("fotograma %d: barra rápida %.1f vs referencia %.1f"
                              % (indice, rapida["kmh"], lenta["kmh"]))
            imagen = Image.fromarray(rgb)
            for cara, nombre in (("throttle", "pedal_acelerador_panel"),
                                 ("brake", "pedal_freno_panel")):
                referencia = sc.pedal_pressure(imagen, sc.region(nombre), cara)
                rapida_p = _pedal_fraccion(rgb, sc.region(nombre), cara)
                if abs(referencia - rapida_p) > 1e-6:
                    fallos.append("fotograma %d %s: %.6f vs referencia %.6f"
                                  % (indice, cara, rapida_p, referencia))
            # El mando se mide con la función de referencia, no con una copia: el
            # único número que hay que vigilar es que se lea. Un fotograma sin
            # lectura no invalida la traza (queda como hueco y el informe dice
            # cuántos), pero sí se cuenta.
    return fallos


def volcar(video: Path, resumen: dict, leer) -> list:
    """Fotogramas de evidencia alrededor de cada suceso, para revisión humana.

    Yo no veo el vídeo: mido. Estos recortes existen para que una persona pueda
    comprobar con sus ojos lo que las medidas afirman, y para que el informe los
    cite. Cada suceso deja una tira de cuatro fotogramas —justo antes, en el
    momento, un poco después y medio segundo después— con la hora y la velocidad
    rotuladas en la propia imagen.
    """
    from PIL import Image, ImageDraw

    FOTOGRAMAS.mkdir(parents=True, exist_ok=True)
    rutas = []
    fps = resumen["fps"]
    for numero, suceso in enumerate(resumen["sucesos"], start=1):
        base = suceso["t_inicio_s"]
        instantes = [max(0.0, base - 0.2), base, base + 0.3, base + 1.0]
        celdas = []
        for instante in instantes:
            indice = min(int(round(instante * fps)), resumen["fotogramas"] - 1)
            rgb = leer(indice)
            imagen = Image.fromarray(rgb).resize((792, 360))
            dibujo = ImageDraw.Draw(imagen)
            kmh = resumen["traza"]["kmh"][indice]
            superficie = resumen["traza"]["superficie"][indice]
            dibujo.rectangle((0, 0, 792, 22), fill=(0, 0, 0))
            dibujo.text((6, 6), "t=%.2f s   %.1f km/h   %s   (fotograma %d)"
                        % (instante, kmh, superficie, indice), fill=(255, 255, 255))
            celdas.append(imagen)
        tira = Image.new("RGB", (792 * 2, 360 * 2))
        for posicion, celda in enumerate(celdas):
            tira.paste(celda, ((posicion % 2) * 792, (posicion // 2) * 360))
        ruta = FOTOGRAMAS / ("%s-suceso%d.jpg" % (video.stem, numero))
        tira.save(ruta, quality=90)
        (FOTOGRAMAS / ("%s-suceso%d.json" % (video.stem, numero))).write_text(
            json.dumps(suceso, indent=2, ensure_ascii=False))
        rutas.append(str(ruta.relative_to(ROOT)))
    return rutas


def sucesos(tiempos, kmh, mando, throttle, brake, superficie, fps: float) -> list:
    """Bloqueos y caídas bruscas de velocidad, con lo que el jugador pedía.

    Un suceso no decide la causa: sólo la acota. Se registra la velocidad antes y
    después, cuánto tarda en caer, si el freno estaba pisado y hacia dónde iba
    puesta la dirección, que es lo que separa «el jugador frena» de «algo para el
    coche».
    """
    salida = []
    n = len(kmh)
    # Centro del mando en reposo: el mínimo desplazamiento sostenido lo da el
    # propio vídeo (la mediana), porque el juego lo centra al soltarlo.
    validos = [m for m in mando if m is not None]
    centro = float(np.median(validos)) if validos else None

    def desplazamiento(i):
        m = mando[i]
        return None if (m is None or centro is None) else round(m - centro, 1)

    # 1. Caídas bruscas: más de CAIDA km/h entre fotogramas consecutivos.
    CAIDA = 12.0
    i = 1
    while i < n:
        brinco = kmh[i - 1] - kmh[i]
        if brinco >= CAIDA:
            inicio = i
            pico = kmh[i - 1]
            fin = i
            while fin + 1 < n and kmh[fin] - kmh[fin + 1] >= CAIDA * 0.5:
                fin += 1
            salida.append({
                "tipo": "caida", "t_inicio_s": round(tiempos[inicio - 1], 3),
                "t_fin_s": round(tiempos[min(fin, n - 1)], 3),
                "kmh_antes": pico, "kmh_despues": kmh[min(fin, n - 1)],
                # Deceleración media del tramo, en g (9,81 m/s^2): es lo que
                # distingue una frenada (≤1,5 g) de un choque (>3 g).
                "g_media": round(((pico - kmh[min(fin, n - 1)]) / 3.6)
                                 / max(1e-3, tiempos[min(fin, n - 1)] - tiempos[inicio - 1]) / 9.81, 2),
                "mando_antes": desplazamiento(max(0, inicio - 6)),
                "mando_despues": desplazamiento(min(n - 1, fin + 6)),
                "acelerador_antes": round(throttle[max(0, inicio - 6)], 3),
                "freno_antes": round(brake[max(0, inicio - 6)], 3),
                "acelerador_despues": round(throttle[min(n - 1, fin + 6)], 3),
                "freno_despues": round(brake[min(n - 1, fin + 6)], 3),
                "superficie_antes": superficie[max(0, inicio - 6)],
                "superficie_despues": superficie[min(n - 1, fin + 6)],
                "fotogramas_60_kmh": None,
                "duracion_s": round(tiempos[min(fin, n - 1)] - tiempos[inicio - 1], 3),
            })
            i = fin + 1
        else:
            i += 1

    # 2. Bloqueos: el coche se queda por debajo de 40 km/h tras ir a más de 120.
    LENTO, RAPIDO, DURACION = 40.0, 120.0, 0.8
    i = 0
    while i < n:
        if kmh[i] <= LENTO:
            j = i
            while j + 1 < n and kmh[j + 1] <= LENTO:
                j += 1
            if tiempos[j] - tiempos[i] >= DURACION and i > 0 and max(kmh[max(0, i - 90):i]) >= RAPIDO:
                # El suceso arranca en el pico de velocidad que lo precede: es el
                # último fotograma en el que el coche iba rápido de verdad.
                ventana = kmh[max(0, i - 90):i]
                antes = max(0, i - 90) + int(np.argmax(ventana))
                salida.append({
                    "tipo": "bloqueo", "t_inicio_s": round(tiempos[antes], 3),
                    "t_fin_s": round(tiempos[j], 3),
                    "kmh_antes": kmh[antes], "kmh_despues": kmh[j],
                    "velocidad_del_bloqueo": [round(v, 1) for v in kmh[i:j + 1][::max(1, (j - i) // 8)]],
                    "mando_en_el_bloqueo": [desplazamiento(k) for k in range(i, j + 1, max(1, (j - i) // 6))],
                    "acelerador_en_el_bloqueo": [round(throttle[k], 3) for k in range(i, j + 1, max(1, (j - i) // 6))],
                    "freno_en_el_bloqueo": [round(brake[k], 3) for k in range(i, j + 1, max(1, (j - i) // 6))],
                    "superficie_al_parar": superficie[i],
                    "superficie_al_final": superficie[j],
                    "duracion_s": round(tiempos[j] - tiempos[i], 3),
                })
            i = j + 1
        else:
            i += 1
    return salida


def auditar(video: Path, paso: int = 1) -> dict:
    import cv2

    captura = cv2.VideoCapture(str(video))
    if not captura.isOpened():
        raise SystemExit("no se puede abrir %s" % video)
    fps = captura.get(cv2.CAP_PROP_FPS)
    total = int(captura.get(cv2.CAP_PROP_FRAME_COUNT))
    ancho = int(captura.get(cv2.CAP_PROP_FRAME_WIDTH))
    alto = int(captura.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print("%s: %.4g fps  %dx%d  %d fotogramas (%.2f s)"
          % (video.name, fps, ancho, alto, total, total / fps))

    def leer(indice: int) -> np.ndarray:
        captura.set(cv2.CAP_PROP_POS_FRAMES, indice)
        ok, bgr = captura.read()
        if not ok:
            raise SystemExit("no se puede leer el fotograma %d" % indice)
        return bgr[:, :, ::-1].copy()

    fotogramas = {"tamano": (ancho, alto), "leer": leer}
    muestras = [int(total * f) for f in (0.02, 0.2, 0.45, 0.7, 0.95)]
    print("verificando las medidas contra las funciones de referencia...")
    fallos = verificar(video, muestras, fotogramas)
    if fallos:
        for fallo in fallos:
            print("  FALLA:", fallo)
        raise SystemExit("las copias rápidas no coinciden con la referencia: no publico la traza")

    sc.usar_geometria(ancho, alto)
    caja_acelerador = sc.region("pedal_acelerador_panel")
    caja_freno = sc.region("pedal_freno_panel")

    from PIL import Image

    tiempos, velocidades, mandos, aceleradores, frenos, superficies = [], [], [], [], [], []
    captura.set(cv2.CAP_PROP_POS_FRAMES, 0)
    indice = 0
    while True:
        ok, bgr = captura.read()
        if not ok:
            break
        rgb = bgr[:, :, ::-1]
        tiempos.append(indice / fps)
        velocidades.append(_barra_kmh(rgb)["kmh"])
        superficies.append(_superficie(rgb))
        if indice % paso == 0:
            mando = sc.knob(Image.fromarray(rgb))
            mandos.append(None if mando is None else mando["cx"])
            aceleradores.append(_pedal_fraccion(rgb, caja_acelerador, "throttle"))
            frenos.append(_pedal_fraccion(rgb, caja_freno, "brake"))
        else:
            mandos.append(mandos[-1] if mandos else None)
            aceleradores.append(aceleradores[-1] if aceleradores else 0.0)
            frenos.append(frenos[-1] if frenos else 0.0)
        indice += 1
    # La captura NO se cierra aquí: los fotogramas de evidencia se leen después.

    centros = [m for m in mandos if m is not None]
    centro_mando = float(np.median(centros)) if centros else None
    eventos = sucesos(tiempos, velocidades, mandos, aceleradores, frenos, superficies, fps)
    resumen = {
        "video": video.name,
        "fps": round(fps, 4),
        "fotogramas": indice,
        "duracion_s": round(tiempos[-1], 3) if tiempos else 0.0,
        "tamano": [ancho, alto],
        "mando_centro_px": centro_mando,
        "mando_leido": len(centros),
        "kmh_min": min(velocidades), "kmh_max": max(velocidades),
        "kmh_medio": round(float(np.mean(velocidades)), 1),
        "sucesos": eventos,
        "fotogramas_de_evidencia": volcar(video, {
            "fps": fps, "fotogramas": indice, "sucesos": eventos,
            "traza": {"kmh": velocidades, "superficie": superficies}}, leer),
        "traza": {
            "t_s": [round(t, 3) for t in tiempos],
            "kmh": velocidades,
            "mando_cx": mandos,
            "acelerador": [round(v, 4) for v in aceleradores],
            "freno": [round(v, 4) for v in frenos],
            "superficie": superficies,
        },
    }
    captura.release()
    SALIDA.mkdir(parents=True, exist_ok=True)
    (SALIDA / (video.stem + ".json")).write_text(json.dumps(resumen, indent=2, ensure_ascii=False))
    with (SALIDA / (video.stem + ".csv")).open("w", newline="") as manejador:
        escritor = csv.writer(manejador)
        escritor.writerow(["t_s", "kmh", "mando_cx", "acelerador", "freno", "superficie"])
        for fila in zip(tiempos, velocidades, mandos, aceleradores, frenos, superficies):
            escritor.writerow([round(fila[0], 3), fila[1],
                               "" if fila[2] is None else fila[2],
                               round(fila[3], 4), round(fila[4], 4), fila[5]])
    return resumen


def traza_decimal(resumen: dict, cada: float = 0.5) -> None:
    """Tabla legible: una fila cada `cada` segundos, con lo medido."""
    t = resumen["traza"]["t_s"]
    kmh = resumen["traza"]["kmh"]
    mando = resumen["traza"]["mando_cx"]
    acc = resumen["traza"]["acelerador"]
    fre = resumen["traza"]["freno"]
    centro = resumen["mando_centro_px"]
    print("  %-7s %-6s %-8s %-6s %-6s %s" % ("t(s)", "km/h", "mando", "acel", "freno", "superficie"))
    siguiente = 0.0
    for i, instante in enumerate(t):
        if instante < siguiente:
            continue
        siguiente = instante + cada
        desvio = "" if (mando[i] is None or centro is None) else "%+.0f" % (mando[i] - centro)
        print("  %-7.2f %-6.1f %-8s %-6.2f %-6.2f %s" % (instante, kmh[i], desvio, acc[i], fre[i],
                                                        resumen["traza"]["superficie"][i]))


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    for ruta in sys.argv[1:]:
        video = Path(ruta).expanduser().resolve()
        resumen = auditar(video)
        print("  km/h: min %.1f  max %.1f  medio %.1f | mando en reposo cx=%s (%d lecturas de %d)"
              % (resumen["kmh_min"], resumen["kmh_max"], resumen["kmh_medio"],
                 resumen["mando_centro_px"], resumen["mando_leido"], resumen["fotogramas"]))
        traza_decimal(resumen)
        print("  sucesos: %d" % len(resumen["sucesos"]))
        for suceso in resumen["sucesos"]:
            print("   ", json.dumps(suceso, ensure_ascii=False))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
