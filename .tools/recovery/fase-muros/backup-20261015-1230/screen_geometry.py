#!/usr/bin/env python3
"""Geometría de la pantalla y de los controles, deducida del propio juego.

Las regiones con las que se mide en el dispositivo salen de la MISMA aritmética
que `scripts/race_hud.gd` y `scripts/touch_controls.gd` aplican al lienzo real:

* todo se ancla a un borde o al centro (telemetría a la izquierda, cronómetro al
  centro, pedales a la derecha, mando arriba-izquierda abajo) y
* todo se escala con la ALTURA, `escala = clamp(alto / 900, 0,68 · 1,32)`.

Eso importa: expresar una región como fracción del ANCHO daría posiciones
equivocadas, porque al cambiar el ancho los pedales (anclados a la derecha) y el
cronómetro (centrado) se mueven en píxeles, y la telemetría y el mando no se
mueven nada. Las constantes de diseño de abajo están copiadas literalmente del
juego, en unidades de un lienzo de 900 px de alto; la escala 1,2 (alto 1080) es
la que tenían las regiones calibradas a mano que este módulo sustituye.

En 2400x1080 las regiones que salen de aquí coinciden con las calibradas
(comprobado con `--selftest`, tolerancia 3 px), y en cualquier otro tamaño salen
donde el juego dibuja de verdad.

Uso:
  screen_geometry.py device --serial emulator-5556     # imprime ANCHOxALTO lógico
  screen_geometry.py regions --size 2424x1080 [--json] # regiones de esa pantalla
  screen_geometry.py test --size WxH --display display.txt
  screen_geometry.py --selftest                        # regiones vs calibración
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

# --- constantes de diseño (copiadas del juego, unidades de 900 px de alto) ----
ESCALA_BASE = 1.2           # la escala con la que se calibraron las regiones
ALTO_BASE = 900.0
ESCALA_MIN, ESCALA_MAX = 0.68, 1.32

# scripts/touch_controls.gd · _layout_controls()
MANDO_CENTRO_X = 155.0      # desde el borde izquierdo
MANDO_CENTRO_Y = 154.0      # desde el borde inferior
MANDO_ANILLO = 214.0
MANDO_RADIO = MANDO_ANILLO * 0.46        # recorrido del mando dentro del anillo
# La caja donde se busca la raya del mando tiene que contener el recorrido
# completo (radio) más la media raya, que se dibuja alrededor del centro del
# disco; si no, un mando llevado al tope se saldría de la caja y la medida diría
# que el mando desapareció. La caja histórica era más corta que el recorrido.
MANDO_RAYA_MEDIA = 20.0
MANDO_MARGEN = 4.5
MANDO_CAJA = MANDO_RADIO + MANDO_RAYA_MEDIA + MANDO_MARGEN
PEDAL_ANCHO = 95.0
PEDAL_ALTO = 192.0
PEDAL_MARGEN_DERECHA = 46.0
PEDAL_ALTO_MARGEN = 33.0                 # del borde inferior al pie del pedal
PEDAL_HUECO = 52.0                       # entre acelerador y freno
PEDAL_RELLENO = (22.0, 16.0)             # área sensible ampliada por lado

# scripts/race_hud.gd · _create_hud() / _layout_hud()
TELEMETRIA_POS = (24.0, 20.0)
TELEMETRIA_TAM = (362.0, 148.0)
VELOCIDAD = (26.0, 18.0, 176.0, 60.0)    # dentro del panel de telemetría
MARCHA = (266.0, 24.0, 58.0, 45.0)
CRONOMETRO_POS_X = -165.0                # centrado: centro ± 165
CRONOMETRO_POS_Y = 20.0
CRONOMETRO_TAM = (330.0, 142.0)
# Botón de cambio de vista (cámara del morro), anclado al borde DERECHO arriba.
# Copiado de scripts/race_hud.gd: `BOTON_MARGEN_X`, `BOTON_MARGEN_Y`, `BOTON_TAM`,
# y la misma aritmética de `_layout_hud` (posición = ancho − (margen + ancho)·escala).
CAMARA_BOTON_MARGEN_X = 24.0
CAMARA_BOTON_MARGEN_Y = 20.0
CAMARA_BOTON_TAM = (196.0, 52.0)

# Regiones calibradas a mano sobre capturas de 2400x1080, sólo para `--selftest`.
# Las seis de paneles son rectángulos del layout del juego (se exige coincidencia
# de 3 px); la del mando se dibujó a ojo alrededor de la raya medida y quedó
# descentrada 15 px hacia abajo-derecha respecto al centro del anillo, así que de
# ella se exige lo que de verdad importa: que contenga el anillo, el recorrido
# del mando y el centro calibrado (ver `selftest`).
CALIBRADAS = {
    "telemetria": (28, 24, 464, 202),
    "cronometro": (1002, 24, 1398, 194),
    "velocidad": (60, 45, 272, 119),
    "marcha": (346, 52, 420, 108),
    "pedal_acelerador": (2204, 790, 2372, 1060),
    "pedal_freno": (2028, 790, 2195, 1060),
}
MANDO_CALIBRADA = (60, 780, 320, 1040)
MANDO_CENTRO_CALIBRADO = (186.0, 895.2)
DESVIO_PANELES_PX = 3
DESVIO_CENTRO_MANDO_PX = 16


def escala(alto: float) -> float:
    return min(max(alto / ALTO_BASE, ESCALA_MIN), ESCALA_MAX)


def _r(*valores: float) -> tuple:
    return tuple(int(round(v)) for v in valores)


def _contiene(caja: tuple, dentro: tuple) -> bool:
    return (caja[0] <= dentro[0] and caja[1] <= dentro[1]
            and caja[2] >= dentro[2] and caja[3] >= dentro[3])


def _solapa(a: tuple, b: tuple) -> bool:
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1])


def geometria(ancho: int, alto: int) -> dict:
    """Regiones y puntos de medida para un lienzo de `ancho` x `alto` píxeles."""
    s = escala(alto)
    # Escala de los desplazamientos cortos (los que en el juego van en píxeles
    # absolutos y por eso no dependen del tamaño de la pantalla).
    d = s / ESCALA_BASE
    centro_x, centro_y = MANDO_CENTRO_X * s, alto - MANDO_CENTRO_Y * s
    caja = MANDO_CAJA * s

    pedal_ancho, pedal_alto = PEDAL_ANCHO * s, PEDAL_ALTO * s
    pedal_pie = alto - PEDAL_ALTO_MARGEN * s
    acelerador_x = ancho - PEDAL_MARGEN_DERECHA * s - pedal_ancho
    freno_x = acelerador_x - PEDAL_HUECO * s - pedal_ancho
    relleno_x, relleno_y = PEDAL_RELLENO[0] * s, PEDAL_RELLENO[1] * s

    def pedal_hitbox(x: float) -> tuple:
        return _r(x - relleno_x, pedal_pie - pedal_alto - relleno_y,
                  x + pedal_ancho + relleno_x, pedal_pie + relleno_y)

    tele_x, tele_y = TELEMETRIA_POS[0] * s, TELEMETRIA_POS[1] * s
    boton_x = ancho - (CAMARA_BOTON_MARGEN_X + CAMARA_BOTON_TAM[0]) * s
    boton_y = CAMARA_BOTON_MARGEN_Y * s
    return {
        "ancho": ancho, "alto": alto, "escala": s, "desplazamiento": d,
        "regiones": {
            "telemetria": _r(tele_x, tele_y, tele_x + TELEMETRIA_TAM[0] * s,
                             tele_y + TELEMETRIA_TAM[1] * s),
            "velocidad": _r(tele_x + VELOCIDAD[0] * s, tele_y + VELOCIDAD[1] * s,
                            tele_x + (VELOCIDAD[0] + VELOCIDAD[2]) * s,
                            tele_y + (VELOCIDAD[1] + VELOCIDAD[3]) * s),
            "marcha": _r(tele_x + MARCHA[0] * s, tele_y + MARCHA[1] * s,
                         tele_x + (MARCHA[0] + MARCHA[2]) * s,
                         tele_y + (MARCHA[1] + MARCHA[3]) * s),
            "cronometro": _r(ancho * 0.5 + CRONOMETRO_POS_X * s, CRONOMETRO_POS_Y * s,
                             ancho * 0.5 + CRONOMETRO_POS_X * s + CRONOMETRO_TAM[0] * s,
                             CRONOMETRO_POS_Y * s + CRONOMETRO_TAM[1] * s),
            "mando": _r(centro_x - caja, centro_y - caja, centro_x + caja, centro_y + caja),
            "pedal_acelerador": pedal_hitbox(acelerador_x),
            "pedal_freno": pedal_hitbox(freno_x),
            # El panel dibujado de cada pedal, sin el relleno del área sensible. Para
            # medir si un pedal está pisado se usa esto y no la caja táctil: alrededor
            # del pedal se ve el circuito, y ese paisaje no es el pedal.
            "pedal_acelerador_panel": _r(acelerador_x, pedal_pie - pedal_alto,
                                         acelerador_x + pedal_ancho, pedal_pie),
            "pedal_freno_panel": _r(freno_x, pedal_pie - pedal_alto,
                                    freno_x + pedal_ancho, pedal_pie),
            "camara_boton": _r(boton_x, boton_y, boton_x + CAMARA_BOTON_TAM[0] * s,
                               boton_y + CAMARA_BOTON_TAM[1] * s),
        },
        # Puntos que pisa el inyector: el centro del pedal y el recorrido del
        # mando, que en el juego se limita al radio del anillo.
        "mando_centro": (centro_x, centro_y),
        "mando_radio": MANDO_RADIO * s,
        "mando_raya_media": MANDO_RAYA_MEDIA * s,
        "mando_caja": caja,
        "mando_derecha": (centro_x + MANDO_RADIO * s, centro_y),
        "mando_izquierda": (centro_x - MANDO_RADIO * s * 0.85, centro_y),
        "pedal_acelerador_centro": (acelerador_x + pedal_ancho * 0.5, pedal_pie - pedal_alto * 0.5),
        "pedal_freno_centro": (freno_x + pedal_ancho * 0.5, pedal_pie - pedal_alto * 0.5),
        "pedal_arriba_y": pedal_pie - pedal_alto + 20.0 * d,
        "pedal_abajo_y": pedal_pie + 2.0 * d,
        # Punto que pisa el inyector para cambiar de vista: centro del botón.
        "camara_boton_centro": (boton_x + CAMARA_BOTON_TAM[0] * s * 0.5,
                                boton_y + CAMARA_BOTON_TAM[1] * s * 0.5),
        "tolerancia_mando": 8.0 * d,      # px de la comprobación de posición
        "tolerancia_centro": 14.0 * d,    # px de la comprobación de retorno
    }


def regiones(ancho: int, alto: int) -> dict:
    return geometria(ancho, alto)["regiones"]


def pantalla_de(serial: str) -> tuple:
    """Tamaño lógico del lienzo del juego: la pantalla en horizontal.

    `wm size` da el tamaño físico en la orientación natural del aparato; el juego
    va en horizontal, así que el lienzo es (alto, ancho). Se informa del
    `override` si lo hubiera (algunos ajustes de desarrollador lo cambian).
    """
    adb = os.environ.get("ADB", "adb")
    salida = subprocess.run([adb, "-s", serial, "shell", "wm", "size"],
                            capture_output=True, text=True, timeout=20.0).stdout
    fisico = None
    for linea in salida.splitlines():
        linea = linea.strip()
        if linea.startswith("Physical size:"):
            fisico = linea.split(":", 1)[1].strip()
        elif linea.startswith("Override size:"):
            fisico = linea.split(":", 1)[1].strip()
    if not fisico or "x" not in fisico:
        raise RuntimeError("no se pudo leer 'wm size' del dispositivo: %r" % salida)
    ancho, alto = (int(v) for v in fisico.lower().split("x"))
    corto, largo = min(ancho, alto), max(ancho, alto)
    return largo, corto


def recorte_de(display_dump: str) -> list:
    """Rectángulos del recorte de pantalla (notch) en coordenadas del lienzo.

    En el volcado del display, `DisplayCutout` trae los `boundingRect` del
    recorte. Se devuelven tal cual: son la zona que el sistema reserva y en la
    que el HUD no debe caer. Si no hay recorte, la lista va vacía.
    """
    import re
    rectangulos = []
    for bloque in re.findall(r"DisplayCutout\{[^}]*boundingRect=\{Bounds=\[([^\]]*)\]", display_dump):
        for par in re.findall(r"Rect\((-?\d+), *(-?\d+) *- *(-?\d+), *(-?\d+)\)", bloque):
            x0, y0, x1, y1 = (int(v) for v in par)
            if x1 > x0 and y1 > y0:
                rectangulos.append((x0, y0, x1, y1))
    return rectangulos


def choque(region: tuple, rectangulo: tuple) -> bool:
    return not (region[2] <= rectangulo[0] or rectangulo[2] <= region[0]
                or region[3] <= rectangulo[1] or rectangulo[3] <= region[1])


def selftest() -> int:
    """Las regiones derivadas deben medir lo mismo que las calibradas a mano.

    No se pide coincidencia literal número a número salvo en los seis paneles,
    que son rectángulos del layout del juego y salen de la misma aritmética. Del
    mando se comprueba lo que hace falta para que la medida siga siendo válida:
    que la caja derivada contenga el anillo, el recorrido completo del mando y el
    centro calibrado, y que su centro no se aleje del centro del anillo (la caja
    histórica estaba descentrada, y por eso su centro difiere en ~15 px).
    """
    g = geometria(2400, 1080)
    print("escala=%.4f  (la calibración se hizo con 1,2)" % g["escala"])
    fallos = 0
    print("%-18s %-24s %-24s %s" % ("región", "calibrada (2400x1080)", "derivada", "máx desvío"))
    for nombre, esperado in CALIBRADAS.items():
        obtenido = g["regiones"][nombre]
        desvio = max(abs(a - b) for a, b in zip(esperado, obtenido))
        estado = "ok" if desvio <= DESVIO_PANELES_PX else "FALLA"
        if desvio > DESVIO_PANELES_PX:
            fallos += 1
        print("%-18s %-24s %-24s %2d px  %s" % (nombre, esperado, obtenido, desvio, estado))

    # El botón de vista no tiene calibración a mano (es nuevo): se comprueba por
    # lo que TIENE que cumplir, que es lo que el enunciado pide del botón —que no
    # tape el mando, ni los pedales, ni el cronómetro— y que quede dentro de la
    # pantalla con su margen.
    boton = g["regiones"]["camara_boton"]
    choques = [nombre for nombre in ("mando", "pedal_acelerador", "pedal_freno",
                                     "cronometro", "telemetria")
               if _solapa(boton, g["regiones"][nombre])]
    dentro = (0 <= boton[0] and boton[2] <= g["ancho"] and 0 <= boton[1] and boton[3] <= g["alto"])
    derecha = boton[0] >= g["ancho"] * 0.5 and boton[1] < g["alto"] * 0.25
    margen = g["ancho"] - boton[2]
    print("camara_boton     %-24s (ancho=%d, sin calibración: es nuevo)"
          % (boton, g["ancho"]))
    print("camara_boton     dentro=%s  arriba a la derecha=%s  margen derecho=%d px  "
          "solapes=%s  %s"
          % (dentro, derecha, margen, choques or "ninguno",
             "ok" if (dentro and derecha and not choques) else "FALLA"))
    if not (dentro and derecha and not choques):
        fallos += 1

    caja = g["regiones"]["mando"]
    cx, cy = g["mando_centro"]
    radio = g["mando_radio"]
    raya = g["mando_raya_media"]     # media raya del mando (24 px a escala 1,2)
    print("mando            %-24s %-24s" % (MANDO_CALIBRADA, caja))
    contenidos = {
        "centro calibrado": (MANDO_CENTRO_CALIBRADO[0], MANDO_CENTRO_CALIBRADO[1],
                             MANDO_CENTRO_CALIBRADO[0], MANDO_CENTRO_CALIBRADO[1]),
        "anillo": (cx - radio, cy - radio, cx + radio, cy + radio),
        "mando en reposo": (cx - raya, cy - raya, cx + raya, cy + raya),
        "recorrido horizontal": (cx - radio - raya, cy - raya, cx + radio + raya, cy + raya),
    }
    for nombre, dentro in contenidos.items():
        if not _contiene(caja, dentro):
            print("FALLA: la caja del mando no contiene %s %s -> %s" % (nombre, dentro, caja))
            fallos += 1
    centro_calibrado_caja = ((MANDO_CALIBRADA[0] + MANDO_CALIBRADA[2]) * 0.5,
                            (MANDO_CALIBRADA[1] + MANDO_CALIBRADA[3]) * 0.5)
    desvio_centro = max(abs(centro_calibrado_caja[0] - cx), abs(centro_calibrado_caja[1] - cy))
    estado = "ok" if desvio_centro <= DESVIO_CENTRO_MANDO_PX else "FALLA"
    if desvio_centro > DESVIO_CENTRO_MANDO_PX:
        fallos += 1
    print("centro del mando derivado: (%.1f, %.1f)  [calibrado (186, 895,2); "
          "centro de la caja histórica (190, 910), desvío %.1f px]  %s"
          % (cx, cy, desvio_centro, estado))
    print("SELFTEST", "ok" if fallos == 0 else "FALLA (%d)" % fallos)
    return 0 if fallos == 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    sub = ap.add_subparsers(dest="cmd")
    p = sub.add_parser("device"); p.add_argument("--serial", required=True)
    p.add_argument("--json", action="store_true")
    p = sub.add_parser("regions"); p.add_argument("--size", required=True)
    p.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    if args.cmd == "device":
        ancho, alto = pantalla_de(args.serial)
        if args.json:
            print(json.dumps({"ancho": ancho, "alto": alto}))
        else:
            print("%dx%d" % (ancho, alto))
        return 0
    if args.cmd == "regions":
        ancho, alto = (int(v) for v in args.size.lower().split("x"))
        g = geometria(ancho, alto)
        if args.json:
            print(json.dumps(g, indent=2, ensure_ascii=False))
        else:
            for nombre, r in g["regiones"].items():
                print("%-18s %s" % (nombre, r))
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
