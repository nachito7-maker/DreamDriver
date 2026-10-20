#!/usr/bin/env python3
"""¿En qué punto del circuito ocurre cada suceso del vídeo?

El coche aparece en la salida del juego (`TrackScript.get_spawn_position()`, 18 m
antes del primer punto de la línea de IA) y el vídeo empieza con el coche parado,
así que la distancia recorrida es la INTEGRAL de la velocidad medida en el HUD.
Con esa distancia se busca la estación de la línea de IA (el mismo `fast_lane.ai`
que carga el juego) y de ahí salen la posición real y la curvatura: la zona del
circuito deja de ser una impresión y pasa a ser un número.

La integración arrastra el error de la medida (la barra del HUD cuantiza a
1,49 km/h por píxel), así que se informa también de la incertidumbre: lo que se
afirma es «estación a ±X m», no «estación exacta».

Uso:
    track_station.py <traza.json> [--eventos t1,t2,...] [--curvatura]
"""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FAST_LANE = ROOT / "assets" / "BarcelonaMoto.fast_lane.ai"
SPAWN_BEHIND_M = 18.0          # track_data.gd: spawn = centerline[0] − tangente·18
PASO_MUESTREO_M = 8.0          # para el perfil de curvatura legible


def cargar_linea(ruta: Path = FAST_LANE) -> list:
    """Puntos (x, y, z) de la línea de IA del circuito, en coordenadas de Godot.

    Mismo formato que lee `scripts/track_data.gd`: cabecera de 16 bytes, número de
    puntos en el desplazamiento 4, y cada punto son tres `float` separados 20
    bytes. La conversión de AC a Godot es (-X, Y, -Z).
    """
    crudo = ruta.read_bytes()
    cuantos = struct.unpack_from("<i", crudo, 4)[0]
    puntos = []
    for i in range(cuantos):
        x, y, z = struct.unpack_from("<fff", crudo, 16 + i * 20)
        puntos.append((-x, y, -z))
    return puntos


def arclength(puntos: list) -> list:
    """Distancia acumulada a lo largo de la línea (m), empezando en el punto 0."""
    acumulada = [0.0]
    for i in range(1, len(puntos)):
        a, b = puntos[i - 1], puntos[i]
        acumulada.append(acumulada[-1] + ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2
                                          + (a[2] - b[2]) ** 2) ** 0.5)
    return acumulada


def curvatura(puntos: list) -> list:
    """Curvatura 1/R (1/m) en cada punto, por el círculo de tres puntos vecinos.

    El signo dice hacia dónde gira en coordenadas de Godot contando desde delante:
    positivo = gira a la izquierda. Lo que importa para nombrar una zona es la
    magnitud y el orden de las curvas a lo largo de la vuelta.
    """
    valores = []
    for i in range(len(puntos)):
        a = puntos[(i - 6) % len(puntos)]
        b = puntos[i]
        c = puntos[(i + 6) % len(puntos)]
        ab = (b[0] - a[0], b[2] - a[2])
        bc = (c[0] - b[0], c[2] - b[2])
        ca = (a[0] - c[0], a[2] - c[2])
        lado_ab = (ab[0] ** 2 + ab[1] ** 2) ** 0.5
        lado_bc = (bc[0] ** 2 + bc[1] ** 2) ** 0.5
        lado_ca = (ca[0] ** 2 + ca[1] ** 2) ** 0.5
        area2 = ab[0] * bc[1] - ab[1] * bc[0]
        if lado_ab * lado_bc * lado_ca < 1e-6 or abs(area2) < 1e-9:
            valores.append(0.0)
            continue
        # Radio circunscrito = (a·b·c) / (4·Área); curvatura = 1/R.
        radio = (lado_ab * lado_bc * lado_ca) / (2.0 * abs(area2))
        signo = 1.0 if area2 > 0 else -1.0
        valores.append(signo / max(radio, 1.0))
    return valores


def integrar(traza: dict) -> list:
    """Distancia recorrida (m) fotograma a fotograma, integrando la velocidad."""
    tiempos = traza["t_s"]
    velocidades = traza["kmh"]
    distancias = [0.0]
    for i in range(1, len(tiempos)):
        dt = tiempos[i] - tiempos[i - 1]
        v_media = (velocidades[i] + velocidades[i - 1]) / 2.0 / 3.6
        distancias.append(distancias[-1] + v_media * dt)
    return distancias


def estacion(distancia: float, acumulada: list) -> dict:
    """Punto de la línea de IA que está a `distancia` del origen de salida."""
    objetivo = distancia - SPAWN_BEHIND_M
    objetivo %= acumulada[-1]
    bajo, alto = 0, len(acumulada) - 1
    while bajo < alto:
        medio = (bajo + alto) // 2
        if acumulada[medio] < objetivo:
            bajo = medio + 1
        else:
            alto = medio
    return {"indice": bajo, "s_m": round(objetivo, 1),
            "vuelta_total_m": round(acumulada[-1], 1)}


def incertidumbre(senal: dict, tamano: list) -> float:
    """Cota del error de la integral por cuantización de la barra del HUD.

    La barra mide 302 px de ancho para 360 km/h, es decir 0,596 km/h por píxel de
    media; se toma el duplo por si el relleno cambia de fila al crecer, y se
    integra ese sesgo constante en todo el tramo: es una cota superior honesta.
    """
    ancho_px = 302.0 * min(max(tamano[1] / 900.0, 0.68), 1.32)
    kmh_por_px = 360.0 / ancho_px * 2.0
    return kmh_por_px / 3.6 * (senal["t_s"][-1] - senal["t_s"][0])


def main() -> int:
    analizador = argparse.ArgumentParser()
    analizador.add_argument("traza", type=Path)
    analizador.add_argument("--eventos", default="")
    analizador.add_argument("--curvatura", action="store_true")
    argumentos = analizador.parse_args()

    traza = json.loads(argumentos.traza.read_text())
    senal = traza["traza"]
    puntos = cargar_linea()
    acumulada = arclength(puntos)
    curvaturas = curvatura(puntos)
    distancias = integrar(senal)

    print("%s: %d fotogramas, %.2f s, %d puntos de la línea de IA, vuelta %.1f m"
          % (traza["video"], len(senal["t_s"]), traza["duracion_s"], len(puntos),
             acumulada[-1]))
    print("cota del error de integración: ±%.1f m" % incertidumbre(senal, traza["tamano"]))

    instantes = [float(v) for v in argumentos.eventos.split(",") if v.strip()]
    if not instantes:
        instantes = [s["t_inicio_s"] for s in traza["sucesos"]]
    print("\n%-8s %-10s %-9s %-8s %-9s %-22s" %
          ("t(s)", "dist(m)", "estación", "R(m)", "giro", "punto (x, y, z)"))
    for instante in instantes:
        indice = min(range(len(senal["t_s"])), key=lambda i: abs(senal["t_s"][i] - instante))
        distancia = distancias[indice]
        posicion = estacion(distancia, acumulada)
        curv = curvaturas[posicion["indice"]]
        radio = 1.0 / abs(curv) if abs(curv) > 1e-6 else float("inf")
        punto = puntos[posicion["indice"]]
        print("%-8.2f %-10.1f %-9d %-8.0f %-9s (%.1f, %.1f, %.1f)" % (
            instante, distancia, posicion["indice"], radio,
            "izquierda" if curv > 0 else "derecha", punto[0], punto[1], punto[2]))

    if argumentos.curvatura:
        print("\nPerfil de la vuelta (cada %.0f m): distancia, R, giro"
              % PASO_MUESTREO_M)
        siguiente = 0.0
        for i, s in enumerate(acumulada):
            if s < siguiente:
                continue
            siguiente = s + PASO_MUESTREO_M
            curv = curvaturas[i]
            radio = 1.0 / abs(curv) if abs(curv) > 1e-6 else float("inf")
            if radio > 900.0:
                continue
            print("  %7.1f m  R=%6.0f m  %s" % (s, radio,
                                                "izquierda" if curv > 0 else "derecha"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
