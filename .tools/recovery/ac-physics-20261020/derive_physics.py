#!/usr/bin/env python3
"""Deriva los parámetros de `scripts/track_data.gd` desde los datos de Assetto Corsa.

Fuentes:
  * RB22 2026: AC2026/rb/data/ (INI sueltos).
  * McLaren MP4/4: data.acd del mod VRC dentro de .tools/recovery/senna-mp44-20261017.
    El ACD se descomprime con `acd.py` usando el nombre del directorio original
    (`vrc_1988_mclaren_mp4-4_r02`) como clave; ver INFORME-FISICAS-AC.md.

Uso:
  python3 derive_physics.py --rb AC2026/rb/data --mclaren-dir /tmp/mclaren-acd-.../extracted
  python3 derive_physics.py --rb ... --mclaren-acd "<ruta>/data.acd" --out valores.json

El script no escribe en el juego: sólo imprime la tabla y, si se pide, un JSON.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import shutil
import tempfile
from pathlib import Path

G = 9.81
RHO = 1.225
V_REF = 100.0  # m/s = 360 km/h, punto de referencia del modelo Godot


# --------------------------------------------------------------------------
# Lectura de INI y LUT
# --------------------------------------------------------------------------
def read_ini(path: Path) -> dict[str, dict[str, str]]:
    sections: dict[str, dict[str, str]] = {}
    current = ""
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1].strip().upper()
            sections.setdefault(current, {})
            continue
        if "=" in line and current:
            key, value = line.split("=", 1)
            sections[current][key.strip().upper()] = value.strip()
    return sections


def read_lut(path: Path) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line or "|" not in line:
            continue
        left, right = line.split("|", 1)
        try:
            points.append((float(left), float(right)))
        except ValueError:
            continue
    points.sort()
    return points


def interp(points: list[tuple[float, float]], x: float) -> float:
    if not points:
        return 0.0
    if x <= points[0][0]:
        return points[0][1]
    if x >= points[-1][0]:
        return points[-1][1]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            if x1 == x0:
                return y0
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return points[-1][1]


def num(section: dict[str, str], key: str, default: float = 0.0) -> float:
    try:
        return float(section[key])
    except (KeyError, ValueError):
        return default


# --------------------------------------------------------------------------
# Aero: evalúa las alas y los controladores dinámicos en un punto de operación
# --------------------------------------------------------------------------
def aero_coefficients(data: Path, speed_kmh: float = 360.0, gas: float = 1.0,
                      steer: float = 0.0, ride_front_m: float = 0.03,
                      ride_rear_m: float = 0.04) -> dict[str, float]:
    aero = read_ini(data / "aero.ini")
    wings: dict[str, dict] = {}
    for name, section in aero.items():
        if not name.startswith("WING_"):
            continue
        cl_name = section.get("LUT_AOA_CL", "")
        cd_name = section.get("LUT_AOA_CD", "")
        gh_cl_name = section.get("LUT_GH_CL", "")
        gh_cd_name = section.get("LUT_GH_CD", "")
        wings[name] = {
            "name": section.get("NAME", name),
            "chord": num(section, "CHORD", 1.0),
            "span": num(section, "SPAN", 1.0),
            "angle": num(section, "ANGLE", 0.0),
            "cl_gain": num(section, "CL_GAIN", 1.0),
            "cd_gain": num(section, "CD_GAIN", 1.0),
            "cl": read_lut(data / cl_name) if cl_name else [],
            "cd": read_lut(data / cd_name) if cd_name else [],
            # Un LUT de altura ausente o con un solo punto equivale a 1,0.
            "gh_cl": read_lut(data / gh_cl_name) if gh_cl_name and (data / gh_cl_name).exists() else [],
            "gh_cd": read_lut(data / gh_cd_name) if gh_cd_name and (data / gh_cd_name).exists() else [],
        }

    inputs = {"SPEED_KMH": speed_kmh, "GAS": gas, "STEER": steer, "BRAKE": 0.0}
    controllers = sorted(
        (name for name in aero if name.startswith("DYNAMIC_CONTROLLER_")),
        key=lambda n: int(n.rsplit("_", 1)[1]),
    )
    log = []
    for controller_name in controllers:
        controller = aero[controller_name]
        wing_name = "WING_" + controller.get("WING", "")
        if wing_name not in wings:
            continue
        mode = controller.get("COMBINATOR", "ADD").upper()
        source = controller.get("INPUT", "")
        lut_name = controller.get("LUT", "")
        if source not in inputs or not lut_name or not (data / lut_name).exists():
            continue
        value = interp(read_lut(data / lut_name), inputs[source])
        old = wings[wing_name]["angle"]
        if mode == "MULT":
            wings[wing_name]["angle"] = old * value
        else:
            wings[wing_name]["angle"] = old + value
        upper = controller.get("UP_LIMIT")
        lower = controller.get("DOWN_LIMIT")
        if upper:
            wings[wing_name]["angle"] = min(wings[wing_name]["angle"], float(upper))
        if lower:
            wings[wing_name]["angle"] = max(wings[wing_name]["angle"], float(lower))
        log.append({
            "controller": controller_name,
            "wing": wing_name,
            "mode": mode,
            "input": source,
            "value": value,
            "angle": wings[wing_name]["angle"],
        })

    total_cl_area = 0.0
    total_cd_area = 0.0
    detail = []
    for wing_name, wing in wings.items():
        area = wing["chord"] * wing["span"]
        # Los LUT de altura son MULTIPLICADORES del coeficiente AOA; Neutral
        # (o un LUT ausente) vale 1,0.
        is_front = wing["name"].upper().startswith("FRONT")
        height = ride_front_m if is_front else ride_rear_m
        gh_cl = interp(wing["gh_cl"], height) if wing["gh_cl"] else 1.0
        gh_cd = interp(wing["gh_cd"], height) if wing["gh_cd"] else 1.0
        cl = (interp(wing["cl"], wing["angle"]) if wing["cl"] else 1.0) * gh_cl * wing["cl_gain"]
        cd = (interp(wing["cd"], wing["angle"]) if wing["cd"] else 1.0) * gh_cd * wing["cd_gain"]
        total_cl_area += cl * area
        total_cd_area += cd * area
        detail.append({
            "wing": wing_name,
            "name": wing["name"],
            "angle": wing["angle"],
            "area_m2": area,
            "cl": cl,
            "cd": cd,
            "cl_area": cl * area,
            "cd_area": cd * area,
            "gh_cl": gh_cl,
            "gh_cd": gh_cd,
        })

    return {
        "cl_area": total_cl_area,
        "cd_area": total_cd_area,
        "downforce_n_at_100ms": 0.5 * RHO * V_REF * V_REF * total_cl_area,
        "drag_n_at_100ms": 0.5 * RHO * V_REF * V_REF * total_cd_area,
        "ride_height_front_m": ride_front_m,
        "ride_height_rear_m": ride_rear_m,
        "controllers": log,
        "wings": detail,
    }


# --------------------------------------------------------------------------
# Motor: LUT de par + turbos + ERS
# --------------------------------------------------------------------------
def engine(data: Path) -> dict[str, float]:
    engine_ini = read_ini(data / "engine.ini")
    power_lut = read_lut(data / "power.lut")
    boost = 0.0
    turbos = []
    for name, section in engine_ini.items():
        if re.fullmatch(r"TURBO_\d+", name):
            boost += num(section, "MAX_BOOST", 0.0)
            turbos.append(num(section, "MAX_BOOST", 0.0))
    ers_lut: list[tuple[float, float]] = []
    ers_path = data / "ers.ini"
    if ers_path.exists():
        ers = read_ini(ers_path)
        curve = ers.get("KINETIC", {}).get("TORQUE_CURVE", "")
        if curve and (data / curve).exists():
            ers_lut = read_lut(data / curve)

    best_power = (0.0, 0.0)
    best_torque = (0.0, 0.0)
    for rpm in range(0, 16501, 50):
        base = interp(power_lut, rpm)
        total = base * (1.0 + boost) + (interp(ers_lut, rpm) if ers_lut else 0.0)
        power = total * rpm * 2.0 * math.pi / 60.0
        if total > best_torque[0]:
            best_torque = (total, rpm)
        if power > best_power[0]:
            best_power = (power, rpm)

    limiter = num(engine_ini.get("ENGINE_DATA", {}), "LIMITER", 0.0)
    idle = num(engine_ini.get("ENGINE_DATA", {}), "MINIMUM", 0.0)
    coast_ref = engine_ini.get("COAST_REF", {})
    coast_torque = num(coast_ref, "TORQUE", 0.0)
    coast_rpm = num(coast_ref, "RPM", 0.0)

    return {
        "turbo_boosts": turbos,
        "boost_sum": boost,
        "peak_torque_nm": best_torque[0],
        "peak_torque_rpm": best_torque[1],
        "peak_power_w": best_power[0],
        "peak_power_rpm": best_power[1],
        "limiter_rpm": limiter,
        "idle_rpm": idle,
        "coast_torque_nm": coast_torque,
        "coast_rpm": coast_rpm,
        "has_ers": bool(ers_lut),
    }


def car_physics(data: Path, label: str, aero_speed_kmh: float) -> dict:
    car = read_ini(data / "car.ini")
    susp = read_ini(data / "suspensions.ini")
    tyres = read_ini(data / "tyres.ini")
    drive = read_ini(data / "drivetrain.ini")
    brakes = read_ini(data / "brakes.ini")
    basic = susp.get("BASIC", {})
    front = susp.get("FRONT", {})
    rear = susp.get("REAR", {})
    front_tyre = tyres.get("FRONT", {})
    rear_tyre = tyres.get("REAR", {})
    gears_section = drive.get("GEARS", {})
    engine_data = engine(data)
    aero = aero_coefficients(data, aero_speed_kmh)
    controls = car.get("CONTROLS", {})

    mass = num(car.get("BASIC", {}), "TOTALMASS")
    wheelbase = num(basic, "WHEELBASE")
    cg_location = num(basic, "CG_LOCATION")
    radius_front = num(front_tyre, "RADIUS")
    radius_rear = num(rear_tyre, "RADIUS")
    basey_front = num(front, "BASEY")
    basey_rear = num(rear, "BASEY")
    cg_height = ((radius_front + basey_front) + (radius_rear + basey_rear)) / 2.0

    count = int(num(gears_section, "COUNT", 0))
    gears = [0.0] + [num(gears_section, f"GEAR_{i}") for i in range(1, count + 1)]
    final = num(gears_section, "FINAL", 1.0)
    first_total = gears[1] * final
    top_total = gears[-1] * final
    peak_wheel_force = engine_data["peak_torque_nm"] * first_total / max(radius_rear, 0.01)
    brake_force = 2.0 * num(brakes.get("DATA", {}), "MAX_TORQUE") / max(radius_rear, 0.01)

    dy_front = num(front_tyre, "DY0", 1.0)
    dy_rear = num(rear_tyre, "DY0", 1.0)
    ls_front = 1.0 - num(front_tyre, "LS_EXPY", 1.0)
    ls_rear = 1.0 - num(rear_tyre, "LS_EXPY", 1.0)

    # Velocidad teórica a la que el motor toca el limitador en la última marcha.
    wheel_rpm_limit = engine_data["limiter_rpm"] / max(top_total, 0.01)
    speed_at_limiter = wheel_rpm_limit / 60.0 * 2.0 * math.pi * radius_rear

    # Carga estática por eje (sin aero) y fuerza máxima de tracción teórica.
    front_axle = mass * cg_location * G
    rear_axle = mass * (1.0 - cg_location) * G
    traction_limit = rear_axle * dy_rear

    lock_deg = num(controls, "STEER_LOCK")
    steer_ratio = num(controls, "STEER_RATIO", 1.0)
    road_lock = math.radians(lock_deg / max(steer_ratio, 0.01))

    spring_front = num(front, "SPRING_RATE")
    spring_rear = num(rear, "SPRING_RATE")
    heave_front = num(susp.get("HEAVE_FRONT", {}), "SPRING_RATE")
    heave_rear = num(susp.get("HEAVE_REAR", {}), "SPRING_RATE")

    damper_front = num(front, "DAMP_BUMP")
    damper_rear = num(rear, "DAMP_BUMP")

    return {
        "label": label,
        "source": str(data),
        "mass_kg": mass,
        "wheelbase_m": wheelbase,
        "cg_location_front_fraction": cg_location,
        "cg_height_m": cg_height,
        "wheel_radius_front_m": radius_front,
        "wheel_radius_rear_m": radius_rear,
        "front_weight_fraction": cg_location,
        "engine": engine_data,
        "gears": gears,
        "final_drive_ratio": final,
        "first_total_ratio": first_total,
        "top_total_ratio": top_total,
        "speed_at_limiter_top_gear_ms": speed_at_limiter,
        "brake_force_n": brake_force,
        "peak_wheel_force_first_n": peak_wheel_force,
        "static_front_axle_n": front_axle,
        "static_rear_axle_n": rear_axle,
        "rear_traction_limit_n": traction_limit,
        "tyre_dy0_front": dy_front,
        "tyre_dy0_rear": dy_rear,
        "tyre_load_sensitivity_front": ls_front,
        "tyre_load_sensitivity_rear": ls_rear,
        "front_grip_fraction": dy_front / (dy_front + dy_rear),
        "steering_road_lock_rad": road_lock,
        "spring_rate_front_n_per_m": spring_front,
        "spring_rate_rear_n_per_m": spring_rear,
        "heave_rate_front_n_per_m": heave_front,
        "heave_rate_rear_n_per_m": heave_rear,
        "damper_tau_front_s": damper_front / spring_front if spring_front else 0.0,
        "damper_tau_rear_s": damper_rear / spring_rear if spring_rear else 0.0,
        "packer_range_front_m": num(front, "PACKER_RANGE"),
        "packer_range_rear_m": num(rear, "PACKER_RANGE"),
        "aero": aero,
    }


def extraction(args) -> Path:
    if args.mclaren_dir:
        return Path(args.mclaren_dir)
    if not args.mclaren_acd:
        raise SystemExit("Falta --mclaren-dir o --mclaren-acd")
    try:
        import acd  # type: ignore
    except ImportError as exc:
        raise SystemExit(
            "acd.py no está instalado. Usa el venv de la auditoría o pasa --mclaren-dir."
        ) from exc
    acd_path = Path(args.mclaren_acd)
    # acd.py deriva la clave del nombre del directorio padre.
    temp = Path(tempfile.mkdtemp(prefix="ac-physics-")) / "vrc_1988_mclaren_mp4-4_r02"
    temp.mkdir(parents=True)
    shutil.copy2(acd_path, temp / "data.acd")
    members = acd.read_file(str(temp / "data.acd"))
    if b"[HEADER]" not in members.get("car.ini", b""):
        raise SystemExit("El ACD no se descifró como texto coherente")
    out = temp / "extracted"
    out.mkdir()
    for name, payload in members.items():
        if "/" in name or "\\" in name or name in {"..", "."}:
            raise SystemExit(f"Nombre de miembro inseguro: {name!r}")
        (out / name).write_bytes(payload)
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rb", default="AC2026/rb/data")
    parser.add_argument("--mclaren-dir")
    parser.add_argument("--mclaren-acd")
    parser.add_argument("--out")
    args = parser.parse_args()

    rb = car_physics(Path(args.rb), "Red Bull RB22 2026", 360.0)
    mclaren = car_physics(extraction(args), "McLaren MP4/4 R02", 360.0)
    report = {"aero_reference": "100 m/s (360 km/h), recta, gas=1", "rb22": rb, "mclaren": mclaren}

    for car in (rb, mclaren):
        print(f"\n=== {car['label']} ===")
        print(f"  masa {car['mass_kg']:.0f} kg | batalla {car['wheelbase_m']:.3f} m | "
              f"CG {car['cg_height_m']:.3f} m | reparto del. {car['front_weight_fraction']:.3f}")
        eng = car["engine"]
        print(f"  motor: {eng['peak_power_w']/1000:.1f} kW @ {eng['peak_power_rpm']:.0f} rpm | "
              f"par {eng['peak_torque_nm']:.1f} Nm @ {eng['peak_torque_rpm']:.0f} rpm | "
              f"turbos {eng['turbo_boosts']} (suma {eng['boost_sum']:.2f}) | ERS {eng['has_ers']}")
        print(f"  marchas: {[round(g, 3) for g in car['gears'][1:]]} final {car['final_drive_ratio']:.3f} | "
              f"1ª total {car['first_total_ratio']:.2f} | punta a limitador {car['speed_at_limiter_top_gear_ms']*3.6:.1f} km/h")
        print(f"  fuerza 1ª (sin recortar) {car['peak_wheel_force_first_n']:.0f} N | "
              f"tracción trasera {car['rear_traction_limit_n']:.0f} N | frenos {car['brake_force_n']:.0f} N")
        print(f"  aero: CL·A {car['aero']['cl_area']:.3f} | CD·A {car['aero']['cd_area']:.3f} | "
              f"carga@100 m/s {car['aero']['downforce_n_at_100ms']:.0f} N")
        print(f"  muelles {car['spring_rate_front_n_per_m']:.0f}/{car['spring_rate_rear_n_per_m']:.0f} N/m "
              f"(heave {car['heave_rate_front_n_per_m']:.0f}/{car['heave_rate_rear_n_per_m']:.0f}) | "
              f"tau {car['damper_tau_front_s']:.3f}/{car['damper_tau_rear_s']:.3f} s")
        print(f"  LS_EXPY -> sensibilidad {car['tyre_load_sensitivity_front']:.3f}/"
              f"{car['tyre_load_sensitivity_rear']:.3f} | reparto agarre {car['front_grip_fraction']:.3f} | "
              f"volante->rueda {math.degrees(car['steering_road_lock_rad']):.2f}°")
        for wing in car["aero"]["wings"]:
            print(f"    {wing['wing']:<7} {wing['name']:<12} angulo {wing['angle']:6.2f} "
                  f"area {wing['area_m2']:.4f} CL {wing['cl']:+.4f} CD {wing['cd']:+.4f}")

    if args.out:
        Path(args.out).write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nJSON: {args.out}")


if __name__ == "__main__":
    main()
