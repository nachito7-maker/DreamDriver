#!/usr/bin/env python3
"""Capturas del coche a distintas velocidades en el DISPOSITIVO.

El juego se relanza para partir de un estado conocido (el coche aparece parado
en la recta de salida) y después se conduce con toques REALES del sistema, los
mismos `input swipe` sostenidos sobre los pedales que usa la comprobación de
toque de `screen_check.py`: nada de teletransportar el coche ni de tocar su
velocidad desde dentro, porque lo que hay que medir es la cámara del juego
obedeciendo a la conducción.

Mientras conduce se capturan pantallazos seguidos, cada uno con la velocidad
leída de la barra del HUD (`#58ddad` sobre 360 km/h, la misma lectura que usa
`.tools/recovery/camera_pixels.py`). El etiquetado no depende de que el coche
vaya exactamente a la velocidad pedida: se captura la realidad y se ordena
después, y la velocidad de cada captura es la que el juego pinta.

Uso:
  capturar_dispositivo.py <serial> <dir-salida> [--size ANCHOxALTO]

Deja `disp-NNN.png` (y `capturas.json` con la velocidad y el instante de cada
una). La medida del coche sobre esas capturas la hace
`camera_pixels.py dispositivo <dir>`.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import screen_check as sc  # noqa: E402  (vive en .tools/recovery/)
import camera_pixels as cp  # noqa: E402

PKG = "com.freebuff.f1oneshot.barcelonamoto"
ACTIVITY = f"{PKG}/com.godot.game.GodotAppLauncher"

PRESS_MS = 4000          # un pisotón sostenido por toque real
GAP_S = 0.35             # entre pisotones, el pie vuelve a su sitio
TOP_KPH = 185.0          # por encima de esto ya se ha visto lo que se pide
MAX_ROUNDS = 8           # 8 × (4,0 s + 0,35 s) ≈ 35 s de conducción
RELAUNCH_TIMEOUT_S = 300.0


def capturar(serial: str, outdir: Path, indice: int, fase: str, registro: list) -> dict:
    """Un pantallazo, con su velocidad leída del HUD."""
    instante = time.monotonic()
    resultado = sc.adb_call(serial, "exec-out", "screencap", "-p", timeout=20.0)
    if resultado.returncode != 0 or len(resultado.stdout) < 1000:
        raise RuntimeError("screencap falló: %s" % resultado.stderr[:200])
    png = outdir / f"disp-{indice:03d}.png"
    png.write_bytes(resultado.stdout)
    barra = cp.velocidad_de_barra(png)
    fila = {"archivo": png.name, "indice": indice, "fase": fase,
            "instante_s": round(instante, 2), "kmh": barra.get("kmh"),
            "relleno_px": barra.get("relleno_px")}
    registro.append(fila)
    return fila


def pisotear(serial: str, region_nombre: str, milisegundos: int = PRESS_MS):
    """Pisa un pedal con un toque real, igual que la comprobación de `layout`.

    El dedo baja en el centro del pedal y sube hasta su borde superior, que en
    el juego es presión total (el pedal es analógico y el recorrido se mide
    sobre el panel dibujado). Se lanza en un hilo porque `input swipe` bloquea
    todo el tiempo que dura el pisotón, y durante ese rato hay que capturar.
    """
    x0, y0, x1, y1 = sc.region(region_nombre)
    x = (x0 + x1) // 2
    y = (y0 + y1) // 2
    subprocess.run([sc.ADB, "-s", serial, "shell", "input", "swipe",
                    str(x), str(y), str(x), str(y0 + 6), str(milisegundos)],
                   check=False, timeout=milisegundos / 1000.0 + 20.0)


def enfoque(serial: str) -> str:
    """Qué ventana tiene el foco ahora mismo, según el propio sistema."""
    salida = sc.adb_call(serial, "shell", "dumpsys", "window", timeout=15.0)
    for linea in salida.stdout.decode(errors="replace").splitlines():
        if "mCurrentFocus" in linea:
            return linea.split("=", 1)[1].strip()
    return ""


def exigir_nuestro(serial: str, momento: str) -> str:
    """Ningún toque sintético puede ir a la app equivocada.

    El emulador es un aparato compartido: si otra aplicación está en primer
    plano, un `input swipe` sobre las coordenadas del pedal se lo come ella. Se
    comprueba el foco antes de cada pisotón y, si no es nuestro juego, se para.
    """
    actual = enfoque(serial)
    if PKG not in actual:
        raise RuntimeError(
            "en %s el foco no es nuestro juego, sino %s: no se pisa ningún pedal"
            % (momento, actual or "desconocido"))
    return actual


def relanzar(serial: str) -> None:
    """Estado conocido: el juego recién arrancado, con el coche en la salida."""
    sc.adb_call(serial, "shell", "am", "force-stop", PKG, timeout=20.0)
    time.sleep(2.0)
    sc.adb_call(serial, "shell", "am", "start", "-W", "-n", ACTIVITY, timeout=60.0)
    inicio = time.monotonic()
    while time.monotonic() - inicio < 60.0:
        if PKG in enfoque(serial):
            break
        time.sleep(2.0)
    else:
        raise RuntimeError("el juego no llegó al primer plano: %s" % enfoque(serial))
    pantalla = None
    while time.monotonic() - inicio < RELAUNCH_TIMEOUT_S:
        exigir_nuestro(serial, "el arranque")
        try:
            pantalla = sc.screencap(serial)
        except RuntimeError:
            pantalla = None
        if pantalla is not None and sc.knob(pantalla) is not None:
            print("DISPOSITIVO HUD dibujado tras %.0f s" % (time.monotonic() - inicio))
            return
        time.sleep(4.0)
    raise RuntimeError("el juego no dibujó su HUD en %.0f s" % RELAUNCH_TIMEOUT_S)


def conducir(serial: str, outdir: Path, region_nombre: str, fase: str,
             registro: list, indice: int, parar_por_debajo_de: float | None) -> int:
    """Pisotea un pedal capturando entre medias hasta cumplir la condición."""
    for ronda in range(1, MAX_ROUNDS + 1):
        exigir_nuestro(serial, "la ronda %d de %s" % (ronda, fase))
        hilo = threading.Thread(target=pisotear, args=(serial, region_nombre))
        hilo.start()
        ultima = None
        while hilo.is_alive():
            ultima = capturar(serial, outdir, indice, fase, registro)
            indice += 1
        hilo.join()
        velocidad = ultima["kmh"] if ultima else None
        print("DISPOSITIVO %s ronda %d: última captura %s km/h" % (fase, ronda, velocidad))
        if velocidad is None:
            continue
        if parar_por_debajo_de is None:
            if velocidad >= TOP_KPH:
                break
        elif velocidad <= parar_por_debajo_de:
            break
        time.sleep(GAP_S)
    return indice


def main() -> int:
    analizador = argparse.ArgumentParser(description=__doc__,
                                         formatter_class=argparse.RawDescriptionHelpFormatter)
    analizador.add_argument("serial")
    analizador.add_argument("outdir", type=Path)
    analizador.add_argument("--size")
    argumentos = analizador.parse_args()

    # Sin búfer: cuando el registro se redirige a un fichero, un corte a mitad de
    # la conducción tiene que dejar dentro todo lo que ya había pasado.
    sys.stdout.reconfigure(line_buffering=True)
    serial, outdir = argumentos.serial, argumentos.outdir
    outdir.mkdir(parents=True, exist_ok=True)
    for viejo in outdir.glob("disp-*.png"):
        viejo.unlink()
    sc.usar_geometria(*sc.tamano_devuelto(argumentos))

    registro: list = []
    relanzar(serial)
    exigir_nuestro(serial, "la salida")
    indice = 1
    print("DISPOSITIVO capturando el coche parado")
    for _ in range(3):
        capturar(serial, outdir, indice, "reposo", registro)
        indice += 1
        time.sleep(0.8)
    print("DISPOSITIVO acelerando con toques reales sobre el acelerador")
    indice = conducir(serial, outdir, "pedal_acelerador", "aceleracion", registro, indice, None)
    print("DISPOSITIVO frenando con toques reales sobre el freno")
    indice = conducir(serial, outdir, "pedal_freno", "frenada", registro, indice, 3.0)
    time.sleep(1.5)
    capturar(serial, outdir, indice, "parado-final", registro)

    velocidades = [f["kmh"] for f in registro if f["kmh"] is not None]
    cobertura = {}
    for objetivo in (0.0, 50.0, 100.0, 150.0, 200.0):
        conocidas = [(abs(v - objetivo), f) for f, v in zip(registro, velocidades)]
        if not conocidas:
            cobertura[str(int(objetivo))] = None
            continue
        distancia, fila = min(conocidas, key=lambda par: par[0])
        cobertura[str(int(objetivo))] = {"archivo": fila["archivo"], "kmh": fila["kmh"],
                                         "desvio_kph": round(distancia, 1)}
    informe = {"capturas": registro, "velocidad_maxima_kph": max(velocidades) if velocidades else None,
               "velocidad_minima_kph": min(velocidades) if velocidades else None,
               "cobertura": cobertura}
    (outdir / "capturas.json").write_text(json.dumps(informe, indent=2, ensure_ascii=False))
    print("DISPOSITIVO %d capturas, velocidad %s..%s km/h"
          % (len(registro), informe["velocidad_minima_kph"], informe["velocidad_maxima_kph"]))
    for objetivo, fila in cobertura.items():
        print("DISPOSITIVO objetivo %4s km/h -> %s" % (objetivo, fila))
    faltan = [o for o, f in cobertura.items() if f is None]
    if faltan:
        print("DISPOSITIVO sin capturas para los objetivos %s" % ",".join(faltan))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
