#!/usr/bin/env python3
"""Conduce el APK instalado fuera del asfalto y mide si el coche sigue rodando.

Compila y despliega `AndroidTouchOfftrack.java`, lanza la maniobra (recta a
fondo, salida a la izquierda, acelerador sostenido fuera del asfalto), captura
la pantalla cada 2 s y calcula cuánto cambia la imagen entre capturas.

Un coche que rueda cambia la escena (la cámara de persecución lo sigue); un
coche clavado contra una barrera invisible deja la imagen casi congelada. Ese
es el criterio: la maniobra pasa si durante la fase de rodadura la imagen sigue
cambiando, y falla si se congela.

    python3 .tools/recovery/offtrack_device_check.py <serial> <dir-salida>
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_logcat import GRAVES as LOG_GRAVES, IGNORADAS as LOG_IGNORADAS  # noqa: E402

PACKAGE = "com.freebuff.f1oneshot.barcelonamoto"
# Sólo cuentan los errores del juego. El registro del emulador trae ruido de la
# plataforma Android (por ejemplo `FeatureFlagsImplExport: ...
# ERROR_PACKAGE_NOT_FOUND: package android.xr`) y avisos del propio motor
# (`E godot : WARNING: Failed to load cached shader`), que no dicen nada de la
# maniobra y la suspendían por un fallo ajeno. Cuenta un error del juego cuando
# lo dice la firma del mensaje (nada de nivel "E" a secas, que en Android
# también llevan los avisos) y quien lo emite es el juego.
def _app_error(line: str) -> bool:
    # Mismo criterio que el resto de la entrega (`check_logcat.py`): cuentan las
    # líneas graves y los errores que firma el propio motor (`E godot`), excluido
    # el aviso de recompilación de shaders, que sale siempre en la primera
    # ejecución y no es un fallo. Los avisos y errores del sistema Android que
    # sólo mencionan el paquete de pasada (`W WindowManager: Exception thrown
    # during dispatchAppVisibility`, `E AppOps: attributionTag not declared in
    # manifest`) no son errores del juego y no suspenden la maniobra.
    if any(grave in line for grave in LOG_GRAVES):
        return True
    return " E godot " in line and not any(ignored in line for ignored in LOG_IGNORADAS)

ROOT = Path(__file__).resolve().parents[2]
SDK = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Library/Android/sdk")))
# Un único cliente ADB para todo: mezclar el del SDK con el de Homebrew hace
# que sus servidores peleen por localhost:5037 y el dispositivo queda "offline".
ADB = os.environ.get("ADB") or str(SDK / "platform-tools/adb")
BUILD_TOOLS = sorted((SDK / "build-tools").glob("*"))[-1]
PLATFORM_JAR = sorted((SDK / "platforms").glob("*/android.jar"))[-1]
PKG = "com.freebuff.f1oneshot.barcelonamoto"
ACTIVITY = f"{PKG}/com.godot.game.GodotAppLauncher"
CAPTURE_SECONDS = 46
CAPTURE_INTERVAL = 2.0
FREEZE_THRESHOLD = 0.01  # fracción de píxeles que cambian entre capturas


def adb(serial: str, *args: str, timeout: float = 60.0) -> subprocess.CompletedProcess:
    return subprocess.run([ADB, "-s", serial, *args], capture_output=True, text=True, timeout=timeout)


def prepare_injector(serial: str) -> None:
    java_dir = ROOT / ".tools/recovery/java-offtrack"
    dex_dir = ROOT / ".tools/recovery/dex-offtrack"
    jar = ROOT / ".tools/recovery/android-touch-offtrack.jar"
    java_dir.mkdir(parents=True, exist_ok=True)
    if dex_dir.exists():
        shutil.rmtree(dex_dir)
    dex_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(["javac", "--release", "11", "-classpath", str(PLATFORM_JAR),
                    "-d", str(java_dir), str(ROOT / ".tools/recovery/AndroidTouchOfftrack.java")],
                   check=True, capture_output=True, text=True)
    subprocess.run([str(BUILD_TOOLS / "d8"), "--output", str(dex_dir), "--lib", str(PLATFORM_JAR),
                    str(java_dir / "AndroidTouchOfftrack.class")], check=True, capture_output=True, text=True)
    subprocess.run(["jar", "cf", str(jar), "classes.dex"], cwd=dex_dir,
                   check=True, capture_output=True, text=True)
    pushed = adb(serial, "push", str(jar), "/data/local/tmp/android-touch-offtrack.jar", timeout=30.0)
    if pushed.returncode != 0:
        raise RuntimeError(f"no se pudo desplegar el inyector: {pushed.stderr}")


def changed_fraction(a: Path, b: Path) -> float:
    from PIL import Image, ImageChops
    first = Image.open(a).convert("L")
    second = Image.open(b).convert("L")
    if first.size != second.size:
        return 1.0
    diff = ImageChops.difference(first, second)
    histogram = diff.histogram()
    total = sum(histogram)
    changed = sum(histogram[20:])
    return changed / max(total, 1)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    serial, outdir = sys.argv[1], Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    for old in outdir.glob("*.png"):
        old.unlink()

    prepare_injector(serial)
    adb(serial, "shell", "logcat", "-c")
    adb(serial, "shell", "am", "force-stop", PKG)
    time.sleep(2)
    started = adb(serial, "shell", "am", "start", "-W", "-n", ACTIVITY)
    print("arranque:", started.stdout.strip().splitlines()[-1] if started.stdout else started.stderr.strip())
    time.sleep(12)

    remote_log = "/data/local/tmp/offtrack.log"
    # El inyector se lanza DESPRENDIDO de la sesión de adb (`nohup ... &`). Si el
    # servidor de adb de este equipo se reinicia a mitad de la maniobra —pasa a
    # menudo porque lo comparten el IDE y el emulador— la sesión cae y el proceso
    # remoto moría con ella (el registro decía "Killed" a los pocos segundos).
    # Desprendido, el corte de la sesión no lo mata y la maniobra se sigue por su
    # propio registro.
    # `setsid` abre una sesión nueva: adbd mata el grupo de procesos de su
    # shell cuando la conexión cae, y con `nohup` solo no bastaba. Comprobado en
    # este emulador: un proceso así sobrevive a `adb kill-server`.
    command = ("nohup setsid sh -c 'CLASSPATH=/data/local/tmp/android-touch-offtrack.jar "
               f"app_process /system/bin AndroidTouchOfftrack > {remote_log} 2>&1' "
               "</dev/null >/dev/null 2>&1 &")
    adb(serial, "shell", command, timeout=30.0)

    shots: list[Path] = []
    phases: list[tuple[str, float]] = []
    began = time.monotonic()
    while time.monotonic() - began < CAPTURE_SECONDS:
        elapsed = round(time.monotonic() - began, 2)
        shot = outdir / f"t{int(elapsed):02d}.png"
        with open(shot, "wb") as handle:
            capture = subprocess.run([ADB, "-s", serial, "exec-out", "screencap", "-p"],
                                     stdout=handle, timeout=30.0)
        if capture.returncode != 0 or shot.stat().st_size < 1000:
            shot.unlink(missing_ok=True)
        else:
            shots.append(shot)
            phases.append((shot.name, elapsed))
        time.sleep(max(0.0, CAPTURE_INTERVAL - ((time.monotonic() - began) - elapsed)))
    device_log = ""
    for _ in range(20):
        device_log = adb(serial, "shell", "cat", remote_log).stdout
        if "PHASE fin" in device_log:
            break
        time.sleep(1.0)
    if "PHASE fin" not in device_log:
        print("OFTRACK FAIL la maniobra no llegó a terminar; registro del inyector: "
              + " | ".join(line.strip() for line in device_log.splitlines()[-4:]))
        (outdir / "android-touch-offtrack.log").write_text(device_log, encoding="utf-8")
        return 1

    (outdir / "android-touch-offtrack.log").write_text(device_log, encoding="utf-8")
    logcat = adb(serial, "shell", "logcat", "-d").stdout
    (outdir / "logcat.txt").write_text(logcat, encoding="utf-8")

    diffs = []
    for first, second in zip(shots, shots[1:]):
        diffs.append({"a": first.name, "b": second.name, "cambio": round(changed_fraction(first, second), 4)})
    # Los primeros segundos son la recta: el coche ya se mueve. La parte final
    # es la rodadura fuera del asfalto, que es la que se juzga.
    tail = diffs[int(len(diffs) * 0.55):] if diffs else []
    frozen = [entry for entry in tail if entry["cambio"] < FREEZE_THRESHOLD]
    errors = [line for line in logcat.splitlines() if _app_error(line)]
    report = {
        "serial": serial,
        "capturas": len(shots),
        "fases_inyector": [line.strip() for line in device_log.splitlines() if line.startswith("PHASE")],
        "cambios": diffs,
        "cambios_finales": tail,
        "capturas_congeladas": frozen,
        "errores_logcat": errors[:20],
    }
    (outdir / "offtrack.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"OFTRACK capturas={len(shots)} fases={report['fases_inyector']}")
    for entry in diffs:
        print(f"OFTRACK cambio {entry['a']} -> {entry['b']}: {entry['cambio']}")
    if not shots:
        print("OFTRACK FAIL no se pudo capturar la pantalla")
        return 1
    if frozen:
        print(f"OFTRACK FAIL la imagen se congela en {len(frozen)} intervalos de la rodadura: "
              + ", ".join(f"{e['a']}->{e['b']}" for e in frozen))
        return 1
    if errors:
        print(f"OFTRACK FAIL errores en el registro del dispositivo ({len(errors)}), primero: {errors[0][:160]}")
        return 1
    print(f"OFTRACK PASS el coche sigue rodando fuera del asfalto: "
          f"{len(tail)} intervalos medidos, cambio mínimo {min(e['cambio'] for e in tail):.3f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
