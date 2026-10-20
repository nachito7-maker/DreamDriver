#!/usr/bin/env python3
"""Reproduce las tablas que `scripts/track_data.gd` monta en el McLaren MP4/4 R02.

Fuente: los INI/LUT extraídos del `data.acd` del mod VRC
(`AC2026/mclaren.7z` → `vrc_1988_mclaren_mp4-4_r02/data.acd`, SHA-256
ff09256f56e4a937f2637c2adfdb4a953f532b168c97908272b81f7b980e9a62).
El ACD se descifra con `acd.py` usando el nombre del directorio como clave; este
script no lo hace por sí solo: recibe la carpeta ya extraída.

Uso:
  python3 derive_mclaren_curves.py /tmp/mclaren-acd-inspection-20261020/extracted

Imprime las listas tal como van en la receta y comprueba los puntos clave.
"""

from __future__ import annotations

import importlib.util
import math
import sys
from pathlib import Path

DERIVE = Path(__file__).resolve().parents[1] / "ac-physics-20261020" / "derive_physics.py"


def load_derive():
    spec = importlib.util.spec_from_file_location("derive_physics", DERIVE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fmt_pairs(values, per_line=4):
    lines = []
    for i in range(0, len(values), per_line):
        chunk = ", ".join("[%.0f, %.3f]" % (x, y) for x, y in values[i:i + per_line])
        lines.append("\t\t\t\t\t" + chunk + ",")
    return "\n".join(lines)


def dy_curve(tyres_text: str, axle: str):
    section = tyres_text.split("[%s]" % axle)[1].split("[")[0]
    for line in section.splitlines():
        if line.startswith("DY_CURVE="):
            raw = line.split("=", 1)[1].strip().strip("()")
            return [(float(a), float(b)) for a, b in (p.split("=") for p in raw.split("|") if p)]
    raise SystemExit("Sin DY_CURVE en [%s]" % axle)


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    data = Path(sys.argv[1])
    dp = load_derive()

    power = dp.read_lut(data / "power.lut")
    turbo = dp.read_lut(data / "turbo0.lut")
    torque = [[float(rpm), round(dp.interp(power, rpm), 2)] for rpm in range(0, 15001, 500)]
    boost = [[float(rpm), round(dp.interp(turbo, rpm), 3)] for rpm in range(0, 13001, 500)]

    best_torque = max(((rpm, dp.interp(power, rpm) * 3.5) for rpm in range(0, 13001, 10)), key=lambda p: p[1])
    best_power = max(
        ((rpm, dp.interp(power, rpm) * 3.5 * rpm * 2 * math.pi / 60.0) for rpm in range(0, 13001, 10)),
        key=lambda p: p[1],
    )

    aero_open = dp.aero_coefficients(data, 360.0, gas=1.0)
    aero_closed = dp.aero_coefficients(data, 360.0, gas=0.0)

    tyres_text = (data / "tyres.ini").read_text()
    loads = [0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 8000, 10000, 12000]
    grips = {}
    for axle, fz0 in (("FRONT", 1206.63), ("REAR", 1809.945)):
        curve = dy_curve(tyres_text, axle)
        reference = dp.interp(curve, fz0)
        grips[axle] = [[float(load), round(1.5 * dp.interp(curve, load) / reference, 3)] for load in loads]

    print("; power.lut (par base, Nm)")
    print(fmt_pairs(torque))
    print("; turbo*.lut (sobrepresion 0..1.25)")
    print(fmt_pairs(boost))
    print("; DY_CURVE normalizada en FZ0 -> [carga por rueda (N), mu]")
    print("front:")
    print(fmt_pairs(grips["FRONT"]))
    print("rear:")
    print(fmt_pairs(grips["REAR"]))

    print(
        "\npar maximo %.2f Nm @ %.0f rpm | potencia maxima %.1f kW @ %.0f rpm"
        % (best_torque[1], best_torque[0], best_power[1] / 1000.0, best_power[0])
    )
    print(
        "aero gas=1: %.0f N y CD*A %.4f | gas=0: %.0f N y CD*A %.4f"
        % (
            aero_open["downforce_n_at_100ms"],
            aero_open["cd_area"],
            aero_closed["downforce_n_at_100ms"],
            aero_closed["cd_area"],
        )
    )

    assert abs(best_power[1] - 457952.6) < 50.0, "la potencia de pico cambio respecto al ACD auditado"
    assert abs(aero_open["downforce_n_at_100ms"] - 20105.2) < 1.0, "la carga a 100 m/s cambio"
    assert abs(aero_closed["downforce_n_at_100ms"] - 19492.7) < 1.0, "la carga con el pedal suelto cambio"
    print("OK: las tablas coinciden con las auditadas del ACD")


if __name__ == "__main__":
    main()
