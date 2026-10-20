#!/usr/bin/env python3
"""A/B de los cambios de la sesión del 16-oct sobre el coche.

Para cada variante: parchea UNA línea de `scripts/car_controller.gd`, pasa la sonda de
agarre (23 s) y la de subviraje (223 s), guarda el registro y deja el archivo como estaba.
La referencia a batir es la ENTREGA (no toca nada):

  curva rapida (entrega):  se abre 0.25 m  deriva 0.28 m/s  velocidad media 218 km/h
  curva rapida (hoy):      se abre 3.97 m  deriva 28.06 m/s velocidad media 198 km/h

Uso: python3 .tools/recovery/pruebas-ab/ab.py [variante ...]
     variantes: snap, altura, banda, transferencia, todas
"""
import os
import shutil
import subprocess
import sys

ROOT = "/Users/indenova/AndroidStudioProjects/F1Godot"
GODOT = f"{ROOT}/.tools/godot/Godot.app/Contents/MacOS/Godot"
OUT = f"{ROOT}/.tools/recovery/pruebas-ab"
CONTROLLER = f"{ROOT}/scripts/car_controller.gd"
ORIGINAL = f"{OUT}/original-car_controller.gd"

VARIANTS = {
    # A: volver a pegar el cuerpo al asfalto por su caja de colisión (como la entrega).
    "snap": [
        ("\tfloor_snap_length = 0.0", "\tfloor_snap_length = 0.65"),
        (
            "\t_apoyar_sobre_la_calzada(delta)\n\tmove_and_slide()\n",
            "\t_apoyar_sobre_la_calzada(delta)\n\tmove_and_slide()\n"
            "\tif wheel_contacts > 0:\n\t\tapply_floor_snap()\n",
        ),
    ],
    # B: subir 10 mm el cuerpo sobre el plano medido (0.01 -> 0.02, como la entrega).
    "altura": [("@export var ride_height_m := 0.01", "@export var ride_height_m := 0.02")],
    # D: servir la altura SIEMPRE con el término proporcional (sin banda muerta), como la
    #    entrega: dentro de la banda muerta sólo manda la velocidad de la referencia, así que
    #    un escalón de la calzada lanza el cuerpo sin nada que lo devuelva.
    "banda": [("@export var ride_deadband_m := 0.02", "@export var ride_deadband_m := 0.0")],
    # C: volver a la transferencia de carga medida fotograma a fotograma.
    "transferencia": [
        (
            "suspension.step(delta, heights, grounded, debug_longitudinal_accel, acceleration_lateral)",
            "suspension.step(delta, heights, grounded, acceleration_longitudinal, acceleration_lateral)",
        )
    ],
}


def patch(pairs):
    with open(CONTROLLER, encoding="utf-8") as handle:
        text = handle.read()
    for old, new in pairs:
        if old not in text:
            raise SystemExit(f"NO ENCONTRADO: {old!r}")
        text = text.replace(old, new, 1)
    with open(CONTROLLER, "w", encoding="utf-8") as handle:
        handle.write(text)


def restore():
    shutil.copyfile(ORIGINAL, CONTROLLER)


def probe(script, headless, log):
    command = [GODOT] + (["--headless"] if headless else []) + ["--path", ".", "--script", f"res://{script}"]
    with open(log, "w", encoding="utf-8") as handle:
        return subprocess.call(command, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT)


def summary(log, markers):
    with open(log, encoding="utf-8", errors="replace") as handle:
        lines = handle.readlines()
    return [line.rstrip() for line in lines if any(m in line for m in markers)]


def main():
    os.makedirs(OUT, exist_ok=True)
    if not os.path.exists(ORIGINAL):
        shutil.copyfile(CONTROLLER, ORIGINAL)
    names = sys.argv[1:] or ["todas"]
    if names == ["todas"]:
        names = list(VARIANTS)
    report = []
    for name in names:
        print(f"\n########## variante {name}", flush=True)
        restore()
        patch(VARIANTS[name])
        log = f"{OUT}/{name}.understeer.log"
        state = probe("scripts/surface_grip_probe.gd", True, f"{OUT}/{name}.agarre.log")
        agarre = summary(f"{OUT}/{name}.agarre.log", ["AGARRE "])
        state2 = probe("scripts/understeer_probe.gd", True, log)
        curvas = summary(log, ["SUBVIRAJE CURVA rapida", "SUBVIRAJE FAIL en la curva rapida"])
        restore()
        report.append(f"--- variante {name} (agarre exit={state}, subviraje exit={state2})")
        report += [f"    {line}" for line in agarre]
        report += [f"    {line}" for line in curvas]
    with open(f"{OUT}/ab-resumen.txt", "w", encoding="utf-8") as handle:
        handle.write("\n".join(report) + "\n")
    print("\n".join(report))
    print("\n(archivo del coche restaurado; resumen en .tools/recovery/pruebas-ab/ab-resumen.txt)")


if __name__ == "__main__":
    main()
