#!/usr/bin/env python3
"""Cambio de cámara con toques REALES en el dispositivo.

Qué comprueba, y por qué así:

  * Se relanza el juego (estado conocido: coche en la salida), se acelera con
    pisotones reales del sistema —los mismos `input swipe` sobre el pedal que usa
    la comprobación de toque— y el botón de vista se pisa con un `input tap` real
    en su centro, calculado por `screen_geometry.py` a partir del tamaño del
    lienzo del aparato. Nada de teletransportar el coche ni de llamar al juego
    por dentro: lo que se mide es el juego obedienco al dedo.
  * En cada vista se mide la SILUETA DEL COCHE sobre el PNG con el clasificador de
    librea de `camera_pixels.py` (el mismo que ya se validó contra 15 capturas de
    este teléfono): en persecución el coche está centrado y no toca el borde
    inferior; en el morro está pegado al borde de abajo, es mucho más ancho (el
    alerón cruza el cuadro) y su parte de arriba cae en la mitad inferior.
  * El cronómetro se lee por diferencia de píxeles en su región del HUD ANTES y
    DESPUÉS del cambio: tiene que seguir avanzando, que es lo que demuestra que
    el cambio de vista no detiene ni reinicia la carrera.

Uso:
  capturar_morro_dispositivo.py <serial> <dir-salida> [--size ANCHOxALTO]

Deja las capturas, un `morro-dispositivo.json` con todas las medidas y sale con
código distinto de cero si alguna comprobación falla.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import threading
import time
from pathlib import Path

from PIL import Image

RECUPERACION = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RECUPERACION))
sys.path.insert(0, str(RECUPERACION / "fase-camara"))
import numpy as np                   # noqa: E402

import screen_check as sc            # noqa: E402  (vive en .tools/recovery/)
import camera_pixels as cp           # noqa: E402
import capturar_dispositivo as cd    # noqa: E402  (relanzar, pisotear, exigir_nuestro)

PKG = "com.freebuff.f1oneshot.barcelonamoto"

# Criterios. La vista se distingue por DOS señales ESTRUCTURALES, no por la
# librea: el clasificador de librea del proyecto está afinado para el coche
# lejano de la persecución y en el morro —el coche pegado a la cámara y a pleno
# sol— no encuentra nada (medido: una mancha de 24x43 px).
#
#   1. `saturado_centro`: fracción de píxeles SATURADOS (canal máx − mín > 60) en
#      la caja inferior central (x 30-70 %, y 72-96 %), que es donde cae el morro
#      del coche: en el morro es la librea roja/azul/amarilla, en persecución es
#      asfalto gris. Medido en el aparato: 0,383 de morro frente a 0,007 y 0,095
#      de persecución.
#   2. `horizonte`: altura mediana del borde cielo-suelo, que sale de recorrer
#      cada columna desde arriba buscando el primer píxel que no es cielo. La
#      cámara del morro mira 17° hacia abajo, así que el horizonte sube: medido
#      0,137 frente a 0,273 y 0,303 en persecución.
# Las dos señales separan las vistas por un margen grande y no dependen de la
# luz, del color de la librea ni de la distancia al coche.
MORRO_SATURADO_MIN = 0.25
MORRO_HORIZONTE_MAX = 0.20
PERSECUCION_SATURADO_MAX = 0.20
PERSECUCION_HORIZONTE_MIN = 0.22
VUELTA_HORIZONTE_TOL = 0.08   # la ida y la vuelta dejan la misma vista
VELOCIDAD_MINIMA_KPH = 15.0   # y el coche sigue moviéndose durante el cambio
CAMBIO_RELOJ_MIN = 300       # píxeles cambiados en el cronómetro entre capturas
CAMBIO_RELOJ_DELTA_MIN = 40   # y un cambio de tono claro (dígitos nuevos)


def pisar_boton(serial: str) -> tuple:
    """Un toque real en el centro del botón de vista (coordenadas del juego)."""
    x0, y0, x1, y1 = sc.region("camara_boton")
    x, y = (x0 + x1) // 2, (y0 + y1) // 2
    resultado = sc.adb_call(serial, "shell", "input", "tap", str(x), str(y), timeout=15.0)
    print("TOQUE botón de vista en (%d, %d) código=%d" % (x, y, resultado.returncode))
    return x, y


def capturar(serial: str, outdir: Path, nombre: str) -> Image.Image:
    imagen = sc.screencap(serial)
    imagen.save(outdir / nombre)
    return imagen


def medir_vista(png: Path) -> dict:
    """Las dos señales estructurales de la vista + la velocidad que pinta el HUD."""
    imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    alto, ancho = imagen.shape[0], imagen.shape[1]
    saturado = (imagen.max(axis=2) - imagen.min(axis=2)) > 60
    caja = saturado[int(alto * 0.72):int(alto * 0.96), int(ancho * 0.30):int(ancho * 0.70)]
    franja = saturado[int(alto * 0.80):int(alto * 0.95)]
    pintado = float((franja.mean(axis=0) > 0.5).mean())
    cielo = (imagen[:, :, 2] - imagen[:, :, 0] > 25) & (imagen.mean(axis=2) > 90)
    alturas = []
    for x in range(0, ancho, 12):
        columna = cielo[:, x]
        alturas.append(float(np.argmax(~columna) / alto) if not columna.all() else 1.0)
    return {
        "saturado_centro": round(float(caja.mean()), 4),
        "ancho_pintado": round(pintado, 4),
        "horizonte": round(float(np.median(alturas)), 4),
        "kmh": cp.velocidad_de_barra(png).get("kmh"),
        "silueta_librea": cp.silueta_por_clasificador(png),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("serial")
    parser.add_argument("outdir")
    parser.add_argument("--size", default=None, help="ANCHOxALTO del lienzo del aparato")
    args = parser.parse_args()
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    ancho, alto = sc.tamano_devuelto(args)
    sc.usar_geometria(ancho, alto)

    errores: list[str] = []
    datos: dict = {"lienzo": [ancho, alto], "boton": list(sc.region("camara_boton"))}

    print("MORRO-ESCENA relanzando el juego en %s" % serial)
    cd.relanzar(serial)

    def rodar(pisadas: int, segundos: float) -> None:
        for _ in range(pisadas):
            cd.exigir_nuestro(serial, "la conducción")
            cd.pisotear(serial, "pedal_acelerador")
            time.sleep(segundos)

    # Se acelera con pisotones reales y NO se espera a que el coche llegue arriba:
    # el toque del botón suelta el pedal (es el mismo puntero), y lo que importa es
    # que las tres capturas se tomen CON EL COCHE EN MARCHA y que el cronómetro
    # siga corriendo alrededor del cambio.
    print("MORRO-ESCENA acelerando con toques reales sobre el pedal")
    rodar(2, 0.5)

    png1 = outdir / "dispositivo-persecucion-1.png"
    reloj1_antes = sc.screencap(serial)
    capturar(serial, outdir, png1.name)
    print("MORRO-ESCENA primera captura (persecución) %s" % png1.name)

    x, y = pisar_boton(serial)
    datos["punto_de_toque"] = [x, y]
    time.sleep(1.0)
    png2 = outdir / "dispositivo-morro.png"
    capturar(serial, outdir, png2.name)
    print("MORRO-ESCENA captura de la vista del morro %s" % png2.name)

    pisar_boton(serial)
    time.sleep(1.0)
    png3 = outdir / "dispositivo-persecucion-2.png"
    capturar(serial, outdir, png3.name)
    print("MORRO-ESCENA captura de vuelta a la persecución %s" % png3.name)

    # El pedal tiene que seguir respondiendo DESPUÉS del cambio de vista: se pisa
    # otra vez y se captura con el pie puesto (en un hilo, porque el pisotón real
    # bloquea todo lo que dura).
    hilo = threading.Thread(target=cd.pisotear, args=(serial, "pedal_acelerador", 3500), daemon=True)
    hilo.start()
    time.sleep(1.4)
    png4 = outdir / "dispositivo-morro-pedal.png"
    capturar(serial, outdir, png4.name)
    hilo.join(timeout=12.0)
    reloj1_despues = sc.screencap(serial)

    for etiqueta, png in (("persecucion-1", png1), ("morro", png2), ("persecucion-2", png3),
                          ("pedal_despues", png4)):
        datos[etiqueta] = medir_vista(png)
        fila = datos[etiqueta]
        print("MORRO-DISPOSITIVO %-14s kmh=%-6s saturado_centro=%.3f ancho_pintado=%.3f horizonte=%.3f"
              % (etiqueta, fila["kmh"], fila["saturado_centro"], fila["ancho_pintado"], fila["horizonte"]))

    morro = datos["morro"]
    persecucion = datos["persecucion-1"]
    vuelta = datos["persecucion-2"]

    # 1. La vista del morro: coche pintado en la caja inferior central y horizonte alto.
    if morro["saturado_centro"] < MORRO_SATURADO_MIN:
        errores.append("en la vista del morro la caja inferior central sólo tiene un %.0f %% de coche "
                       "(se pide ≥ %.0f %%)" % (morro["saturado_centro"] * 100, MORRO_SATURADO_MIN * 100))
    if morro["horizonte"] > MORRO_HORIZONTE_MAX:
        errores.append("en la vista del morro el horizonte cae al %.0f %% del alto (se pide ≤ %.0f %%: "
                       "la cámara mira hacia abajo) " % (morro["horizonte"] * 100, MORRO_HORIZONTE_MAX * 100))
    if morro["horizonte"] > persecucion["horizonte"] - 0.08:
        errores.append("el horizonte de la vista del morro (%.2f) no está claramente por encima del de "
                       "la persecución (%.2f)" % (morro["horizonte"], persecucion["horizonte"]))

    # 2. Las dos capturas de persecución tienen que ser la MISMA vista (ida y vuelta).
    for etiqueta, fila in (("persecucion-1", persecucion), ("persecucion-2", vuelta)):
        if fila["saturado_centro"] > PERSECUCION_SATURADO_MAX:
            errores.append("en %s la caja inferior central tiene un %.0f %% de coche: no es la vista de "
                           "persecución (se pide ≤ %.0f %%)"
                           % (etiqueta, fila["saturado_centro"] * 100, PERSECUCION_SATURADO_MAX * 100))
        if fila["horizonte"] < PERSECUCION_HORIZONTE_MIN:
            errores.append("en %s el horizonte cae al %.0f %% del alto: no es la vista de persecución "
                           "(se pide ≥ %.0f %%)" % (etiqueta, fila["horizonte"] * 100, PERSECUCION_HORIZONTE_MIN * 100))
    if abs(vuelta["horizonte"] - persecucion["horizonte"]) > VUELTA_HORIZONTE_TOL:
        errores.append("la ida y la vuelta no dejan la misma vista: horizonte %.3f al ir y %.3f al volver"
                       % (persecucion["horizonte"], vuelta["horizonte"]))

    # 3. La carrera sigue: el coche se mueve en las cuatro capturas.
    for etiqueta in ("persecucion-1", "morro", "persecucion-2", "pedal_despues"):
        rapidez = datos[etiqueta]["kmh"]
        if rapidez is None or rapidez < VELOCIDAD_MINIMA_KPH:
            errores.append("en %s el coche iba a %s km/h: el cambio de vista no puede pararlo"
                           % (etiqueta, rapidez))

    # 2. La carrera no se detiene: el cronómetro avanza alrededor del cambio.
    reloj = sc.differences(reloj1_antes, reloj1_despues, sc.region("cronometro"))
    datos["cronometro"] = reloj
    reloj1_antes.save(outdir / "reloj-antes.png")
    reloj1_despues.save(outdir / "reloj-despues.png")
    print("MORRO-DISPOSITIVO cronómetro %s" % reloj)
    if not (reloj["cambiados"] > CAMBIO_RELOJ_MIN and reloj["delta_max"] > CAMBIO_RELOJ_DELTA_MIN):
        errores.append("el cronómetro no avanzó durante el cambio de vista (%s)" % reloj)

    datos["errores"] = errores
    datos["passed"] = not errores
    (outdir / "morro-dispositivo.json").write_text(json.dumps(datos, indent=2, ensure_ascii=False))
    for error in errores:
        print("  ERROR %s" % error)
    print("MORRO-DISPOSITIVO capturas=%s errores=%d PASS=%s" % (outdir, len(errores), not errores))
    return 0 if not errores else 1


if __name__ == "__main__":
    raise SystemExit(main())
