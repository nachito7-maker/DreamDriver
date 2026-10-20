#!/usr/bin/env python3
"""Prueba EN EL APARATO de los pedales pisados ABAJO, en el borde y moviendo el dedo.

Es el caso que dejaba el coche parado: el mapeo anterior pedía ~5 % de gas con el dedo al pie
del pedal y CERO si el dedo caía en el margen lateral de la zona, así que el pedal se
iluminaba y el coche no andaba. Aquí se pisa con gestos de verdad del sistema
(`input swipe` sostenido, la misma familia de órdenes que usa la comprobación `toque` de
`screen_check.py`) y se mide la velocidad en la barra del HUD, no un valor interno.

Uso:
  toque_pedales_abajo.py <serial> [--size 2424x1080]

Sale distinto de cero si alguna pulsación no mueve el coche como debe.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import camera_pixels as cp  # noqa: E402
import screen_check as sc  # noqa: E402

PKG = "com.freebuff.f1oneshot.barcelonamoto"
ACTIVITY = f"{PKG}/com.godot.game.GodotAppLauncher"
TMP = Path("/tmp/toque-pedales")


def adb(serial: str, *args: str, timeout: float = 30.0) -> str:
    r = sc.adb_call(serial, *args, timeout=timeout)
    if r.returncode != 0:
        raise RuntimeError(f"adb {args} falló: {r.stderr[:200]}")
    return r.stdout.decode(errors="replace")


def velocidad(serial: str) -> float:
    # `exec-out screencap -p` devuelve de vez en cuando un PNG cortado (es el mismo corte de
    # adb que ya obliga a reintentar la batería): se reintenta y se valida el final del PNG.
    TMP.mkdir(parents=True, exist_ok=True)
    png = TMP / "pantalla.png"
    ultimo = ""
    for _ in range(4):
        r = sc.adb_call(serial, "exec-out", "screencap", "-p", timeout=25.0)
        datos = r.stdout
        if r.returncode == 0 and datos[:8] == b"\x89PNG\r\n\x1a\n" and datos.rstrip().endswith(b"IEND\xaeB`\x82"):
            png.write_bytes(datos)
            try:
                dato = cp.velocidad_de_barra(png)
            except OSError as error:
                ultimo = str(error)
                continue
            if dato.get("kmh") is not None:
                return float(dato["kmh"])
            ultimo = str(dato)
        else:
            ultimo = f"PNG cortado ({len(datos)} bytes)"
        time.sleep(0.4)
    raise RuntimeError(f"no se pudo leer la velocidad del HUD: {ultimo}")


def gesto(serial: str, x0: float, y0: float, x1: float, y1: float, ms: int) -> float:
    """Pisón sostenido con el dedo: `input swipe` del mismo punto = mantener; de punta a punta
    = mover el dedo SIN levantarlo, que es lo que hay que probar. La orden bloquea mientras
    dura el gesto, así que se lanza en un hilo y se muestrea la velocidad EN MEDIO del pisón
    (medirla al final mediría el coche ya sin dedo encima). Devuelve la velocidad máxima vista."""
    import threading

    def inyectar() -> None:
        sc.adb_call(serial, "shell", "input", "swipe",
                    str(int(x0)), str(int(y0)), str(int(x1)), str(int(y1)), str(ms),
                    timeout=ms / 1000.0 + 25.0)

    hilo = threading.Thread(target=inyectar, daemon=True)
    hilo.start()
    maxima = 0.0
    restante = ms / 1000.0
    while restante > 0.3:
        time.sleep(min(0.9, restante - 0.2))
        maxima = max(maxima, velocidad(serial))
        restante -= 0.9
    hilo.join(timeout=30.0)
    return maxima


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("serial")
    ap.add_argument("--size", default=None)
    args = ap.parse_args()
    ancho, alto = (int(v) for v in (args.size or "2424x1080").split("x"))
    sc.usar_geometria(ancho, alto)
    escala = min(max(alto / 900.0, 0.68), 1.32)
    # Geometría de los pedales, la misma que calcula `touch_controls._layout_controls`.
    ancho_pedal, alto_pedal = 95.0 * escala, 192.0 * escala
    margen, hueco = 46.0 * escala, 52.0 * escala
    fondo = alto - 33.0 * escala
    gas_cx = ancho - margen - ancho_pedal * 0.5
    freno_cx = gas_cx - hueco - ancho_pedal * 0.5
    arriba, abajo = fondo - alto_pedal, fondo
    print(f"TOQUE_PEDAL dispositivo {ancho}x{alto} escala={escala:.2f} "
          f"acelerador x={gas_cx:.0f} y={arriba:.0f}..{abajo:.0f} freno x={freno_cx:.0f}")

    adb(args.serial, "shell", "am", "force-stop", PKG)
    time.sleep(2)
    adb(args.serial, "shell", "am", "start", "-W", "-n", ACTIVITY, timeout=60.0)
    # El juego tarda en dibujar el HUD (compila shaders la primera vez): no se inyecta nada
    # hasta que la barra de velocidad existe, o los toques caerían en la pantalla de arranque.
    # `screen_check.py ready` es la espera de la batería: hasta que el juego no dibuja su HUD
    # no se inyecta nada (los primeros toques caerían en la pantalla de arranque y se mediría
    # un cero que no es del mando).
    listo = False
    for _ in range(30):
        r = subprocess.run([sys.executable, str(Path(sc.__file__)), "ready", args.serial,
                            "--size", f"{ancho}x{alto}"], capture_output=True, timeout=120.0)
        if r.returncode == 0:
            listo = True
            break
        time.sleep(5)
    foco = adb(args.serial, "shell", "dumpsys", "window", timeout=12.0)
    print("TOQUE_PEDAL foco=" + ",".join(l.strip() for l in foco.splitlines() if "mCurrentFocus" in l)[:160]
          + f" hud_listo={listo}")
    if not listo:
        print("TOQUE_PEDAL FAIL el HUD no llegó a dibujarse; sin HUD la velocidad no se puede leer")
        return 1

    fallos = 0

    def comprobar(nombre: str, v0: float, v1: float, minimo: float, sube: bool = True) -> None:
        nonlocal fallos
        delta = v1 - v0
        bien = delta >= minimo if sube else delta <= -minimo
        print(f"TOQUE_PEDAL {'PASS' if bien else 'FAIL'} {nombre}: {v0:.0f} -> {v1:.0f} km/h "
              f"(delta {delta:+.0f}, exigido {'+' if sube else '-'}{minimo:.0f})")
        if not bien:
            fallos += 1

    # 1. Gas pisado ABAJO del pedal (donde cae el pulgar). Antes: ~5 % de demanda.
    v0 = velocidad(args.serial)
    maxima = gesto(args.serial, gas_cx, abajo - 10.0, gas_cx, abajo - 10.0, 4000)
    comprobar("acelerador pisado al pie del pedal", v0, maxima, 12.0)

    # 2. Gas pisado ARRIBA (control: en las dos versiones pedía el total).
    v0 = velocidad(args.serial)
    maxima = gesto(args.serial, gas_cx, arriba + 10.0, gas_cx, arriba + 10.0, 4000)
    comprobar("acelerador pisado arriba (control)", v0, maxima, 25.0)

    # 3. Gas mantenido mientras el dedo se va al margen lateral de la zona: antes la demanda
    #    caía a cero y el coche dejaba de acelerar.
    v0 = velocidad(args.serial)
    maxima = gesto(args.serial, gas_cx, abajo - 90.0, gas_cx - 90.0, abajo - 90.0, 3500)
    comprobar("acelerador moviendo el dedo al borde lateral", v0, maxima, 10.0)

    # 4. Freno pisado al pie del pedal: tiene que frenar de verdad.
    v0 = velocidad(args.serial)
    # El freno se mide con la velocidad mínima vista durante el pisón (medirla al final mediría
    # el coche ya sin el pie encima).
    minima = 400.0
    import threading as _th
    def inyectar() -> None:
        sc.adb_call(args.serial, "shell", "input", "swipe", str(int(freno_cx)), str(int(abajo - 10.0)),
                    str(int(freno_cx)), str(int(abajo - 10.0)), "3000", timeout=45.0)
    hilo = _th.Thread(target=inyectar, daemon=True)
    hilo.start()
    for _ in range(4):
        time.sleep(0.8)
        minima = min(minima, velocidad(args.serial))
    hilo.join(timeout=30.0)
    comprobar("freno pisado al pie del pedal", v0, minima, 20.0, sube=False)

    print(f"TOQUE_PEDAL {'PASS' if not fallos else 'FAIL'} comprobaciones=4 fallos={fallos}")
    return 0 if not fallos else 1


if __name__ == "__main__":
    raise SystemExit(main())
