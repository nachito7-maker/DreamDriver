#!/usr/bin/env python3
"""Comprueba orientación, tamaño de lienzo y barras del sistema ocultas.

No exige ninguna resolución concreta: lee la del aparato (`init=`, `cur=`, `app=`
del volcado del display y el marco de la ventana del juego) y comprueba que el
juego la ocupa ENTERA, en horizontal y sin barras. Lo que sí depende de dónde
dibuja el juego —HUD, mando, pedales— lo mide `screen_check.py`, que deriva sus
regiones del tamaño detectado: aquí sólo se comprueba el continente.

Criterios:

  * orientación horizontal: la rotación actual es la que el PROPIO aparato declara
    como paisaje (`mLandscapeRotation`, o `mSeascapeRotation` si el lienzo está al
    revés), y además el tamaño lógico es más ancho que alto. No se escribe ningún
    `ROTATION_90` a mano: hay paneles cuyo paisaje nativo es `ROTATION_0` —el AVD
    `PRO`/Pixel 9a de esta batería, con `mLandscapeRotation=ROTATION_0` y
    `mPortraitRotation=ROTATION_270`— y exigir 90/270 ahí daba un fallo falso con
    la ventana del juego perfectamente horizontal, a pantalla completa y sin
    barras. Sólo si el volcado no declara ninguna de las dos se cae a 90/270, que
    es lo correcto en un panel de paisaje nativo vertical,
  * el tamaño lógico actual (`cur`) es la pantalla física en horizontal: ni un
    recorte ni un escalado. Si el juego se acotara a sí mismo con bandas, `cur`
    seguiría siendo el del display y lo que cambiaría es el marco de su ventana,
    que es el criterio siguiente,
  * el área de aplicación (`app`) es la pantalla entera,
  * la ventana del juego pide y recibe el marco completo (mismo tamaño que el
    display), que es lo que descarta bandas negras por modo de compatibilidad,
  * las barras del sistema están ocultas en todos los estados que publica el
    display.

Uso:  check_display.py <display.txt> <ventanas.txt> [--size ANCHOxALTO]

`--size` es el tamaño que la batería midió en el aparato antes de arrancar el
juego, que es con el que se miden las regiones del HUD. Se exige que coincida con
el tamaño lógico del display para que una medida y otra no puedan discrepar en
silencio.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

PAQUETE = "com.freebuff.f1oneshot.barcelonamoto"


def _uno(patron: str, texto: str, defecto=None):
    hallado = re.search(patron, texto)
    return hallado.groups() if hallado else defecto


def _tamano(valor: str | None) -> tuple | None:
    if not valor or "x" not in valor:
        return None
    ancho, alto = (int(v) for v in valor.lower().split("x"))
    return ancho, alto


def ventana_del_juego(windows: str) -> str:
    """El bloque del volcado de ventanas que describe la ventana del juego."""
    inicio = windows.find(PAQUETE)
    if inicio < 0:
        return ""
    arranque = windows.rfind("  Window #", 0, inicio)
    siguiente = windows.find("\n  Window #", inicio)
    return windows[arranque if arranque >= 0 else inicio:
                   siguiente if siguiente > 0 else len(windows)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("display")
    ap.add_argument("ventanas")
    ap.add_argument("--size", help="tamaño medido en el aparato antes de arrancar")
    args = ap.parse_args()
    display = Path(args.display).read_text(errors="replace")
    windows = Path(args.ventanas).read_text(errors="replace")
    ok = True

    # --- tamaño del aparato y tamaño lógico actual ---------------------------
    fisico = _tamano(_uno(r"init=(\d+x\d+)", display, (None,))[0])
    actual = _tamano(_uno(r"cur=(\d+x\d+)", display, (None,))[0])
    aplicacion = _tamano(_uno(r"app=(\d+x\d+)", display, (None,))[0])
    if not fisico or not actual:
        print("no se pudo leer el tamaño del display (init=/cur=):", fisico, actual)
        return 1
    lienzo = (max(fisico), min(fisico))            # el aparato en horizontal
    print("pantalla física %dx%d · lienzo horizontal esperado %dx%d · tamaño lógico actual %s"
          % (fisico[0], fisico[1], lienzo[0], lienzo[1], actual))
    print("GEOMETRIA %dx%d" % actual)

    if actual[0] <= actual[1]:
        print("la pantalla no está en horizontal: tamaño lógico %dx%d" % actual)
        ok = False
    if tuple(sorted(actual)) != tuple(sorted(fisico)):
        print("el tamaño lógico actual %s no es el del aparato %s: el sistema está "
              "recortando o escalando la superficie" % (actual, fisico))
        ok = False
    if aplicacion and aplicacion != actual:
        print("el área de aplicación %s no cubre el tamaño lógico %s" % (aplicacion, actual))
        ok = False
    if args.size:
        medido = _tamano(args.size)
        if medido != actual:
            print("el tamaño medido en el aparato (%s) y el lógico del display (%s) no "
                  "coinciden: se estaría midiendo el HUD con otra geometría"
                  % (args.size, actual))
            ok = False
        else:
            print("el tamaño medido en el aparato coincide con el display: %s" % args.size)

    # --- orientación declarada ----------------------------------------------
    # El paisaje lo declara el aparato, no una constante: `mLandscapeRotation` es
    # la rotación que el panel considera horizontal (0 en un panel horizontal
    # nativo, 90 en uno vertical), y `mSeascapeRotation` la misma al revés.
    rotacion = _uno(r"mDisplayRotation=(ROTATION_\d+)", display, (None,))[0]
    paisaje = _uno(r"mLandscapeRotation=(ROTATION_\d+)", display, (None,))[0]
    marino = _uno(r"mSeascapeRotation=(ROTATION_\d+)", display, (None,))[0]
    declaradas = {r for r in (paisaje, marino) if r}
    esperadas = declaradas if declaradas else {"ROTATION_90", "ROTATION_270"}
    if rotacion in esperadas:
        print("rotación %s (horizontal: el aparato declara %s como paisaje)"
              % (rotacion, "/".join(sorted(declaradas)) if declaradas else "90/270"))
    else:
        print("la pantalla no está en horizontal: mDisplayRotation=%s y el aparato "
              "declara %s como paisaje"
              % (rotacion, "/".join(sorted(declaradas)) if declaradas else "90/270"))
        ok = False

    # --- la ventana del juego ocupa el display ------------------------------
    juego = ventana_del_juego(windows)
    if not juego:
        print("no se encontró la ventana del juego (%s) en el volcado" % PAQUETE)
        ok = False
    else:
        marcos = _uno(r"Frames: parent=\[(\d+),(\d+)\]\[(\d+),(\d+)\] "
                      r"display=\[(\d+),(\d+)\]\[(\d+),(\d+)\] "
                      r"frame=\[(\d+),(\d+)\]\[(\d+),(\d+)\]", juego)
        pedido = _uno(r"Requested w=(\d+) h=(\d+)", juego)
        util = _uno(r"mAppBounds=Rect\((\d+), (\d+) - (\d+), (\d+)\)", juego)
        rotacion_ventana = _uno(r"mDisplayRotation=(ROTATION_\d+)", juego, (None,))[0]
        print("ventana del juego: pedido=%s pares=%s util=%s rotación=%s"
              % (pedido, marcos, util, rotacion_ventana))
        if pedido and (int(pedido[0]), int(pedido[1])) != lienzo:
            print("la ventana del juego pide %sx%s y la pantalla es %dx%d"
                  % (pedido[0], pedido[1], lienzo[0], lienzo[1]))
            ok = False
        if marcos:
            numeros = [int(v) for v in marcos]
            marco = tuple(numeros[0:4])
            marco_display = tuple(numeros[4:8])
            marco_frame = tuple(numeros[8:12])
            completo = (0, 0, lienzo[0], lienzo[1])
            for etiqueta, valor in (("parent", marco), ("display", marco_display),
                                    ("frame", marco_frame)):
                if valor != completo:
                    print("el marco %s de la ventana del juego es %s y debería ser %s"
                          % (etiqueta, valor, completo))
                    ok = False
            if len({marco, marco_display, marco_frame}) > 1:
                print("la ventana del juego no ocupa el display: parent=%s display=%s frame=%s "
                      "(bandas o modo de compatibilidad)" % (marco, marco_display, marco_frame))
                ok = False
        else:
            print("no se encontraron los marcos (Frames: parent/display/frame) de la ventana del juego")
            ok = False
        if util and (int(util[0]), int(util[1]), int(util[2]), int(util[3])) \
                != (0, 0, lienzo[0], lienzo[1]):
            print("el área útil de la ventana del juego es %s y debería ser %s"
                  % (util, (0, 0, lienzo[0], lienzo[1])))
            ok = False

    # --- barras del sistema ocultas -----------------------------------------
    # Solo las líneas de estado de las barras: `InsetsSource` en el volcado del
    # display. `[^\n]*?visible=(...)` no cruza de línea. El volcado de `windows`
    # (por ventana) solo describe las peticiones de cada ventana
    # (`InsetsFrameProvider`, sin campo `visible`) y por eso se usa de contraste.
    for tipo in ("statusBars", "navigationBars"):
        vistas = re.findall(r"type=%s[^\n]*?visible=(true|false)" % tipo, display)
        visibles = [v for v in vistas if v == "true"]
        if not vistas:
            print("no se encontró el estado de las barras:", tipo)
            ok = False
        elif visibles:
            print("las barras del sistema siguen visibles: %s en %d de %d estados"
                  % (tipo, len(visibles), len(vistas)))
            ok = False
        else:
            print("barras %s ocultas en %d de %d estados" % (tipo, len(vistas), len(vistas)))
        pedidas = re.findall(r"type=%s" % tipo, windows)
        print("  peticiones de esa barra en las ventanas:", len(pedidas))

    print("DISPLAY PASS=", ok)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
