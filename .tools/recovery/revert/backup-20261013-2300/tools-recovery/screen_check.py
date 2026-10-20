#!/usr/bin/env python3
"""Comprobaciones sobre la pantalla REAL del dispositivo.

Nada de aquí deduce nada del código: se mide lo que el juego pinta. Las regiones
no son arbitrarias, salen de la geometría que `scripts/race_hud.gd` y
`scripts/touch_controls.gd` calculan para un lienzo de 2400x1080 (escala 1,2),
y están comprobadas contra capturas del dispositivo:

  telemetría       (28, 24)-(464, 202)    tarjeta izquierda: velocidad, marcha…
  cronómetro      (1002, 24)-(1398, 194)  panel central con el tiempo de vuelta
  velocidad         (60, 45)-(272, 119)   los dígitos de km/h
  marcha           (346, 52)-(420, 108)   la marcha
  mando             (60, 780)-(320, 1040) el anillo del joystick
  pedal acelerador      x 2204..2372, y 790..1060
  pedal freno           x 2028..2195, y 790..1060

Uso:
  screen_check.py layout   <png>
  screen_check.py ready    <serial>
  screen_check.py clock    <serial> <dir-salida>
  screen_check.py touch    <serial> <dir-salida>

`ready` y `clock` hablan con el dispositivo: hacen sus propias capturas para
que la medición no dependa de cuándo las pida el shell. `layout` y el análisis
interno de `touch` trabajan sobre ficheros ya capturados.
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

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
REGIONS = {
    "telemetria": (28, 24, 464, 202),
    "cronometro": (1002, 24, 1398, 194),
    "velocidad": (60, 45, 272, 119),
    "marcha": (346, 52, 420, 108),
    "mando": (60, 780, 320, 1040),
    "pedal_acelerador": (2204, 790, 2372, 1060),
    "pedal_freno": (2028, 790, 2195, 1060),
}
# Colores declarados en el juego, que es lo que permite localizar los mandos.
KNOB = (33, 43, 53)             # disco del mando, Color(0.13,0.17,0.21,0.85)
PEDAL_THROTTLE = (98, 237, 177)  # borde del acelerador, Color("#62edb1")
PEDAL_BRAKE = (255, 119, 106)    # borde del freno, Color("#ff776a")
LERDO = 6                        # tolerancia entre canales


ADB = os.environ.get("ADB", "adb")


def adb_call(serial: str, *args: str, timeout: float = 12.0) -> subprocess.CompletedProcess:
    """One bounded device call; never block screen sampling on a sick emulator."""
    return subprocess.run([ADB, "-s", serial, *args], capture_output=True, timeout=timeout)


def screencap(serial: str) -> Image.Image:
    result = adb_call(serial, "exec-out", "screencap", "-p", timeout=10.0)
    if result.returncode != 0 or len(result.stdout) < 1000:
        raise RuntimeError("screencap falló: %s" % result.stderr[:200])
    return Image.open(io.BytesIO(result.stdout)).convert("RGB")


def blob(image: Image.Image, target, tolerance: int, region) -> dict | None:
    box = image.crop(region)
    pixels = box.load()
    xs, ys = [], []
    for y in range(box.size[1]):
        for x in range(box.size[0]):
            c = pixels[x, y]
            if abs(c[0] - target[0]) <= tolerance and abs(c[1] - target[1]) <= tolerance \
                    and abs(c[2] - target[2]) <= tolerance:
                xs.append(x + region[0])
                ys.append(y + region[1])
    if not xs:
        return None
    return {"n": len(xs), "cx": sum(xs) // len(xs), "cy": sum(ys) // len(ys),
            "x0": min(xs), "y0": min(ys), "x1": max(xs), "y1": max(ys)}


def knob(image: Image.Image) -> dict | None:
    return blob(image, KNOB, 14, REGIONS["mando"])


def pedal_pressure(image: Image.Image, region: tuple, face: tuple) -> float:
    """Estimate a pressed pedal from its face color, independently of HUD text."""
    x0, y0, x1, y1 = region
    crop = image.crop((x0, y0, x1, y1))
    pixels = crop.load()
    count = 0
    for y in range(crop.height):
        for x in range(crop.width):
            c = pixels[x, y]
            if face == "throttle":
                if c[1] > c[0] * 1.35 and c[1] > c[2] * 1.15 and c[1] > 55:
                    count += 1
            elif c[0] > c[1] * 1.35 and c[0] > c[2] * 1.25 and c[0] > 60:
                count += 1
    return count / max(1, crop.width * crop.height)


def differences(a: Image.Image, b: Image.Image, region, threshold: int = 20) -> dict:
    box_a = a.crop(region)
    box_b = b.crop(region)
    diff = ImageChops.difference(box_a, box_b).convert("L")
    hist = diff.histogram()
    total = box_a.size[0] * box_a.size[1]
    changed = sum(hist[threshold + 1:])
    top = max((i for i, v in enumerate(hist) if v), default=0)
    return {"cambiados": changed, "total": total, "fraccion": round(changed / total, 4),
            "delta_max": top}


def black_columns(image: Image.Image) -> list:
    pixels = image.load()
    width, height = image.size
    columns = []
    for x in range(width):
        dark = 0
        for y in range(0, height, 8):
            c = pixels[x, y]
            if c[0] + c[1] + c[2] < 24:
                dark += 1
        if dark >= height // 8 - 2:
            columns.append(x)
    return columns


def cmd_layout(args) -> int:
    image = Image.open(args.png).convert("RGB")
    if image.size != (2400, 1080):
        print("LAYOUT tamaño inesperado:", image.size)
        return 1
    kn = knob(image)
    pedal = blob(image, PEDAL_THROTTLE, LERDO, REGIONS["pedal_acelerador"])
    black = black_columns(image)
    print("LAYOUT mando:", kn)
    print("LAYOUT pedal_acelerador:", pedal)
    print("LAYOUT columnas_negras=%d %s" % (len(black), (min(black), max(black)) if black else ""))
    ok = True
    if kn is None or abs(kn["cx"] - 186) > 8 or abs(kn["cy"] - 895) > 8:
        print("LAYOUT FALLA: el mando no está en su sitio (2400x1080, escala 1,2)")
        ok = False
    if pedal is None or pedal["x1"] > REGIONS["pedal_acelerador"][2] or pedal["x0"] < REGIONS["pedal_acelerador"][0]:
        print("LAYOUT FALLA: el pedal del acelerador no está donde toca")
        ok = False
    if black:
        print("LAYOUT FALLA: hay %d columnas negras (bandas laterales)" % len(black))
        ok = False
    print("LAYOUT PASS=", ok)
    return 0 if ok else 1


def cmd_ready(args) -> int:
    """0 solo si el juego ya dibuja su HUD.

    El anuncio `[track]` del registro sale antes del primer fotograma: la
    primera vez el emulador compila los shaders y la pantalla sigue un rato en
    la imagen de arranque. El mando del joystick pertenece al HUD, así que
    verlo es la prueba de que el juego ya está dibujando de verdad.
    """
    image = screencap(args.serial)
    kn = knob(image)
    print("READY mando:", kn)
    return 0 if kn is not None else 1


PEDAL_MS = 4500


def throttle_press(serial: str, milliseconds: int = PEDAL_MS) -> None:
    """Pisa el pedal del acelerador con un toque real del sistema.

    Las coordenadas salen de la misma región que usa la comprobación de
    `layout`, no de números escritos a mano. El dedo baja en el centro del
    pedal y sube hasta su borde superior, que en el juego es presión total.
    """
    x0, y0, x1, y1 = REGIONS["pedal_acelerador"]
    x = (x0 + x1) // 2
    y = (y0 + y1) // 2
    subprocess.run([ADB, "-s", serial, "shell", "input", "swipe",
                    str(x), str(y), str(x), str(y0 + 6), str(milliseconds)],
                   check=False, timeout=10.0)


def cmd_clock(args) -> int:
    """El cronómetro tiene que avanzar en el dispositivo.

    El coche aparece justo antes de la línea de meta y el cronómetro no cuenta
    hasta que la cruza, así que sobre el coche parado la pantalla no cambia y la
    medida sería un falso negativo. Si la primera pareja de capturas sale igual,
    se acelera el coche con toques reales -como haría una persona- y se vuelve a
    medir hasta que cruce. Si aun así no avanza, es un fallo: el juego no está
    pintando, o el cronómetro no cuenta.
    """
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    def pareja():
        antes = screencap(serial)
        time.sleep(3.0)
        despues = screencap(serial)
        return antes, despues, differences(antes, despues, REGIONS["cronometro"])

    antes, despues, clock = pareja()
    arranque = "ya contaba"
    if not (clock["cambiados"] > 300 and clock["delta_max"] > 40):
        print("CLOCK parado: el coche aún no ha cruzado la meta; se acelera de verdad")
        for intento in range(1, 7):
            throttle_press(serial)
            time.sleep(1.0)
            antes, despues, clock = pareja()
            print("CLOCK intento %d:" % intento, clock)
            if clock["cambiados"] > 300 and clock["delta_max"] > 40:
                arranque = "arrancó tras %d pulsaciones reales del acelerador" % intento
                break

    antes.save(outdir / "reloj-1.png")
    despues.save(outdir / "reloj-2.png")
    print("CLOCK cronometro:", clock)
    print("CLOCK arranque:", arranque)
    ok = clock["cambiados"] > 300 and clock["delta_max"] > 40
    print("CLOCK PASS=", ok, "(el cronómetro avanza en el dispositivo)")
    return 0 if ok else 1


def cmd_touch(args) -> int:
    serial, outdir = args.serial, Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    devlog = "/data/local/tmp/touch.log"
    adb_call(serial, "shell", "rm", "-f", devlog, timeout=5.0)
    video_path = outdir / "touch.mp4"
    remote_video = "/data/local/tmp/touch-screenrecord.mp4"
    remote_diag = "/data/local/tmp/touch-screenrecord.log"
    adb_call(serial, "shell", "rm", "-f", remote_video, timeout=5.0)
    adb_call(serial, "shell", "rm", "-f", remote_diag, timeout=5.0)
    adb_call(serial, "shell", "touch", devlog, timeout=5.0)
    injector_class = Path(".tools/recovery/java/AndroidTouch.class")
    if not injector_class.is_file():
        raise RuntimeError("AndroidTouch.class no está compilado; prepara primero toque_jar")
    # Keep the game foregrounded; InputManager dispatch rejects a hidden SurfaceView.
    focus = adb_call(serial, "shell", "dumpsys", "window", timeout=12.0).stdout.decode(errors="replace")
    if "com.freebuff.f1oneshot.barcelonamoto" not in focus:
        adb_call(serial, "shell", "am", "start", "-n",
                 "com.freebuff.f1oneshot.barcelonamoto/com.godot.game.GodotAppLauncher", timeout=15.0)
        time.sleep(3.0)
    pushed = adb_call(serial, "push", str(Path(".tools/recovery/android-touch.jar")),
                      "/data/local/tmp/android-touch.jar", timeout=20.0)
    if pushed.returncode != 0:
        raise RuntimeError("No se pudo enviar el inyector multitáctil: %s" % pushed.stderr[:200])
    # screenrecord saves the rendered Android Surface; pull only after the
    # encoder has closed its MP4 container.
    recording_start = time.monotonic()
    recorder_log = outdir / "screenrecord.log"
    recorder_stream = recorder_log.open("wb")
    # El inyector recorre ahora nueve fases (idle, acelerador, freno, multitáctil,
    # retorno, freno+dirección, liberación total): la grabación tiene que cubrir
    # la secuencia completa sin cortar la última fase, que es donde se mide el
    # retorno del mando al centro tras soltar todo.
    recorder = subprocess.Popen(
        [ADB, "-s", serial, "shell", "screenrecord", "--time-limit", "75",
         "--bit-rate", "1500000", remote_video],
        stdout=recorder_stream, stderr=subprocess.PIPE)
    markers = []
    stop = threading.Event()

    def follow():
        reader = subprocess.Popen([ADB, "-s", serial, "shell", "tail", "-f", "-n", "+1", devlog],
                                  stdout=subprocess.PIPE, text=True, bufsize=1)
        for line in reader.stdout:
            line = line.strip()
            if line.startswith("PHASE") or line.endswith("_DOWN") or line.endswith("_UP"):
                markers.append((time.monotonic(), line))
            if stop.is_set():
                break
        reader.terminate()

    follower = threading.Thread(target=follow, daemon=True)
    follower.start()

    # Let the recorder initialize before launching the sole privileged injector.
    time.sleep(2.0)
    remote_injector = "CLASSPATH=/data/local/tmp/android-touch.jar app_process /system/bin AndroidTouch > %s 2>&1" % devlog
    launcher = subprocess.Popen(
        [ADB, "-s", serial, "shell", remote_injector],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    frames = []
    start = recording_start
    try:
        recorder.wait(timeout=85.0)
    except subprocess.TimeoutExpired:
        recorder.terminate()
        try:
            recorder.wait(timeout=5.0)
        except subprocess.TimeoutExpired:
            recorder.kill()
            recorder.wait()
        print("TOUCH grabador no terminó dentro de 85 s")
    try:
        launcher.wait(timeout=8.0)
    except subprocess.TimeoutExpired:
        launcher.terminate()
        try:
            launcher.wait(timeout=3.0)
        except subprocess.TimeoutExpired:
            launcher.kill()
            launcher.wait()
        print("TOUCH inyector no salió al terminar la grabación")
    stop.set()
    follower.join(timeout=3.0)
    recorder_stream.close()
    pulled = adb_call(serial, "pull", remote_video, str(video_path), timeout=25.0)
    if pulled.returncode != 0:
        raise RuntimeError(pulled.stderr.decode(errors="replace")[:240])
    try:
        import cv2
        capture = cv2.VideoCapture(str(video_path))
        fps = capture.get(cv2.CAP_PROP_FPS)
        count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if not capture.isOpened() or fps <= 0 or count < 10:
            raise RuntimeError("grabación ilegible: fps=%s frames=%s" % (fps, count))
        for index in range(count):
            ok, bgr = capture.read()
            if not ok:
                continue
            image = Image.fromarray(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB))
            frames.append({"t": round(index / fps, 2),
                           "velocidad": image.crop(REGIONS["velocidad"]),
                           "marcha": image.crop(REGIONS["marcha"]),
                           "mando": image.crop(REGIONS["mando"]),
                           "cx": (knob(image) or {}).get("cx"),
                           "gas": pedal_pressure(image, REGIONS["pedal_acelerador"], "throttle"),
                           "freno": pedal_pressure(image, REGIONS["pedal_freno"], "brake")})
        capture.release()
    except (RuntimeError, OSError, ImportError) as error:
        print("TOUCH captura de vídeo falló:", error)
        if recorder_log.is_file():
            print("TOUCH grabador:", recorder_log.read_text(errors="replace")[-1000:])
    marker_times = {line: round(stamp - start, 2) for stamp, line in markers}
    print("TOUCH marcas_temporales=%s" % marker_times)
    phases = {}
    end_i = None
    brake_steer_i = brake_steer_release_i = release_i = release_confirm_i = None
    # Identify the phases from control feedback painted on screen, not adb
    # timestamps: emulator scheduling can distort that clock under GPU load.
    def first_index(predicate, begin=0):
        return next((i for i in range(begin, len(frames)) if predicate(frames[i])), None)
    throttle_i = first_index(lambda f: f["gas"] >= 0.30)
    gas_release_i = first_index(lambda f: throttle_i is not None and f["gas"] < 0.30 and
                                f["t"] >= frames[throttle_i]["t"] + 7.0,
                                (throttle_i + 1) if throttle_i is not None else 0)
    brake_i = first_index(lambda f: gas_release_i is not None and f["freno"] >= 0.30,
                          (gas_release_i + 1) if gas_release_i is not None else 0)
    brake_release_i = first_index(lambda f: brake_i is not None and f["freno"] < 0.30 and
                                  f["t"] >= frames[brake_i]["t"] + 5.0,
                                  (brake_i + 1) if brake_i is not None else 0)
    multi_i = first_index(lambda f: brake_release_i is not None and f["gas"] >= 0.30,
                          (brake_release_i + 1) if brake_release_i is not None else 0)
    steer_i = first_index(lambda f: multi_i is not None and f["cx"] is not None and f["cx"] >= 250,
                          (multi_i + 1) if multi_i is not None else 0)
    end_i = first_index(lambda f: steer_i is not None and f["cx"] is not None and 176 <= f["cx"] <= 205,
                         (steer_i + 1) if steer_i is not None else 0)
    end_confirm_i = first_index(lambda f: end_i is not None and f["cx"] is not None and 176 <= f["cx"] <= 205,
                                (end_i + 1) if end_i is not None else 0)
    # Freno + direccion simultaneos: es la primera fase con el freno pisado y el
    # acelerador suelto despues del retorno del multitactil anterior.
    brake_steer_i = first_index(lambda f: end_confirm_i is not None and f["freno"] >= 0.30 and f["gas"] < 0.30,
                                (end_confirm_i + 1) if end_confirm_i is not None else 0)
    brake_steer_release_i = first_index(lambda f: brake_steer_i is not None and f["freno"] < 0.30,
                                        (brake_steer_i + 1) if brake_steer_i is not None else 0)
    # Liberacion total: ni pedales ni direccion, con el mando ya en el centro.
    release_i = first_index(lambda f: brake_steer_release_i is not None and f["cx"] is not None
                            and 176 <= f["cx"] <= 205 and f["gas"] < 0.30 and f["freno"] < 0.30,
                            (brake_steer_release_i + 1) if brake_steer_release_i is not None else 0)
    release_confirm_i = first_index(lambda f: release_i is not None and f["cx"] is not None
                                    and 176 <= f["cx"] <= 205 and f["gas"] < 0.30 and f["freno"] < 0.30,
                                    (release_i + 1) if release_i is not None else 0)
    if throttle_i is not None and brake_i is not None and multi_i is not None and steer_i is not None and end_confirm_i is not None:
        phases = {"idle": frames[0]["t"], "throttle": frames[throttle_i]["t"],
                  "brake": frames[brake_i]["t"], "multitouch": frames[multi_i]["t"]}
        phases["end"] = frames[end_i]["t"]
        phases["end_confirm"] = frames[end_confirm_i]["t"]
        phases["direccion"] = frames[steer_i]["t"]
        if brake_steer_i is not None:
            phases["brake_steer"] = frames[brake_steer_i]["t"]
        if release_i is not None:
            phases["release"] = frames[release_i]["t"]
        print("TOUCH fases_renderizadas=%s" % phases)
        print("TOUCH freno_direccion=%s/%s liberacion=%s/%s" %
              (brake_steer_i, brake_steer_release_i, release_i, release_confirm_i))
    else:
        print("TOUCH no se detectaron todas las fases en vídeo: throttle=%s brake=%s multitouch=%s steer=%s end=%s end_confirm=%s" %
              (throttle_i, brake_i, multi_i, steer_i, end_i, end_confirm_i))

    if frames:
        (outdir / "capture-metadata.json").write_text(json.dumps({
            "fps_video": round(fps, 3), "frames": len(frames),
            "duracion_video_s": round(len(frames) / fps, 2) if fps > 0 else None,
            "marcas_inyector_s": marker_times,
            "fases_video_s": phases,
            "presion_color_gas": [round(f["gas"], 4) for f in frames],
            "presion_color_freno": [round(f["freno"], 4) for f in frames],
            "direccion_cx": [f["cx"] for f in frames],
        }, indent=2, ensure_ascii=False))
    print("TOUCH frame_times_start=%.2f frame_times_end=%.2f" % (
        frames[0]["t"], frames[-1]["t"]) if frames else "TOUCH sin fotogramas")
    recorder_stream.close()
    stop.set()
    try:
        device_log = adb_call(serial, "shell", "cat", devlog, timeout=12.0).stdout.decode(errors="replace")
    except (subprocess.TimeoutExpired, OSError) as error:
        device_log = "ERROR leyendo log táctil: %s" % error
    (outdir / "android-touch.log").write_text(device_log)
    if len(frames) < 10:
        print("TOUCH PASS=False (demasiado pocas capturas: %d; mira ADB, touch.mp4 y logs del emulador)" % len(frames))
        (outdir / "touch.json").write_text(json.dumps({"fases": phases, "frames": len(frames),
            "fps_video": round(fps, 3) if 'fps' in locals() else None,
            "video": str(video_path), "error": "capturas insuficientes"}, indent=2, ensure_ascii=False))
        return 1

    idle = frames[:throttle_i] if throttle_i is not None else []
    throttle = frames[throttle_i:gas_release_i] if throttle_i is not None and gas_release_i is not None else []
    brake = frames[brake_i:brake_release_i] if brake_i is not None and brake_release_i is not None else []
    multi = frames[multi_i:end_i] if multi_i is not None and end_i is not None else []
    end = frames[end_i:end_confirm_i + 1] if end_i is not None and end_confirm_i is not None else []
    if not all((idle, throttle, brake, multi, end)):
        counts = {"idle": len(idle), "throttle": len(throttle), "brake": len(brake),
                  "multitouch": len(multi), "end": len(end)}
        print("TOUCH PASS=False (alguna fase no tiene capturas: %s)" % counts)
        (outdir / "touch.json").write_text(json.dumps({
            "fases": phases, "frames": len(frames), "fps_video": round(fps, 3),
            "video": str(video_path), "frames_por_fase": counts,
            "error": "fases sin capturas suficientes",
        }, indent=2, ensure_ascii=False))
        return 1

    baseline_speed, baseline_gear = idle[-1]["velocidad"], idle[-1]["marcha"]

    def score(frame, reference, key):
        diff = ImageChops.difference(frame[key], reference).convert("L")
        hist = diff.histogram()
        return sum(hist[26:])

    speed_throttle = max(score(f, baseline_speed, "velocidad") for f in throttle)
    gear_throttle = max(score(f, baseline_gear, "marcha") for f in throttle)
    gas_idle = idle[-1]["gas"]
    gas_press = max(f["gas"] for f in throttle)
    gas_slide_release = min((f["gas"] for f in frames[gas_release_i:brake_i]), default=1.0)
    last_throttle = throttle[-1]["velocidad"]
    speed_brake = max(score(f, last_throttle, "velocidad") for f in brake)
    brake_idle = idle[-1]["freno"]
    brake_press = max(f["freno"] for f in brake)
    brake_slide_release = min((f["freno"] for f in frames[brake_release_i:multi_i]), default=1.0)
    speed_multi = max(score(f, baseline_speed, "velocidad") for f in multi)
    cx_multi = max((f["cx"] or -1) for f in multi)
    cx_steer = max((f["cx"] for f in multi if f["cx"] is not None), default=-1)
    cx_idle = idle[-1]["cx"]
    cx_end = end[-1]["cx"]
    # Freno + direccion a la vez, medidos en la misma grabacion. La direccion va
    # al lado contrario del multitactil, asi que lo que se exige es un desvio
    # real hacia la izquierda respecto al reposo, no un simple cambio.
    bs = frames[brake_steer_i:brake_steer_release_i] if brake_steer_i is not None and brake_steer_release_i is not None else []
    release = frames[release_i:release_confirm_i + 1] if release_i is not None and release_confirm_i is not None else []
    bs_brake = max((f["freno"] for f in bs), default=0.0)
    bs_gas = max((f["gas"] for f in bs), default=0.0)
    bs_cx_left = min((f["cx"] for f in bs if f["cx"] is not None), default=-1)
    bs_speed = max((score(f, bs[0]["velocidad"], "velocidad") for f in bs), default=0) if bs else 0
    release_press = max([f["gas"] for f in release] + [f["freno"] for f in release], default=1.0)
    release_cx = release[-1]["cx"] if release else None
    report = {
        "fases": phases,
        "frames": len(frames),
        "fps_video": round(fps, 3),
        "video": str(video_path),
        "mando_cx_reposo": cx_idle,
        "mando_cx_multitouch": cx_multi,
        "mando_cx_desvio_maximo": cx_steer,
        "mando_cx_final": cx_end,
        "mando_cx_confirmacion_centro": end[-1]["cx"],
        "velocidad_cambio_gas": speed_throttle,
        "marcha_cambio_gas": gear_throttle,
        "velocidad_cambio_freno": speed_brake,
        "velocidad_cambio_multitouch": speed_multi,
        "gas_presion_reposo_pantalla": round(gas_idle, 4),
        "gas_presion_pantalla_max": round(gas_press, 4),
        "gas_liberacion_analogica": round(gas_slide_release, 4),
        "freno_presion_reposo_pantalla": round(brake_idle, 4),
        "freno_presion_pantalla_max": round(brake_press, 4),
        "freno_liberacion_analogica": round(brake_slide_release, 4),
        "freno_direccion_fase_s": phases.get("brake_steer"),
        "freno_direccion_presion_max": round(bs_brake, 4),
        "freno_direccion_gas_max": round(bs_gas, 4),
        "freno_direccion_cx_izquierda": bs_cx_left,
        "freno_direccion_cambio_velocidad": bs_speed,
        "liberacion_fase_s": phases.get("release"),
        "liberacion_cx": release_cx,
        "liberacion_presion_max": round(release_press, 4),
    }
    print("TOUCH", json.dumps(report, ensure_ascii=False))
    ok = True
    if gas_press - gas_idle < 0.15 or speed_throttle < 200 or gear_throttle < 40:
        print("TOUCH FALLA: el acelerador en pantalla no produce cambio de velocidad/marcha")
        ok = False
    if gas_slide_release > gas_idle + max(0.08, 0.35 * (gas_press - gas_idle)):
        print("TOUCH FALLA: al deslizar al fondo del acelerador no libera suficiente presión respecto al reposo")
        ok = False
    if brake_press - brake_idle < 0.15 or speed_brake < 200:
        print("TOUCH FALLA: el freno en pantalla no produce cambio de velocidad")
        ok = False
    if brake_slide_release > brake_idle + max(0.08, 0.35 * (brake_press - brake_idle)):
        print("TOUCH FALLA: al deslizar al fondo del freno no libera suficiente presión respecto al reposo")
        ok = False
    if cx_steer < 0 or cx_idle is None or cx_steer - cx_idle < 40:
        print("TOUCH FALLA: el joystick no se desplaza al pisar el acelerador a la vez")
        ok = False
    if speed_multi < 200:
        print("TOUCH FALLA: las dos entradas simultáneas no llegan al coche")
        ok = False
    if cx_end is None or abs(cx_end - 186) > 14 or abs(end[-1]["cx"] - 186) > 14:
        print("TOUCH FALLA: el mando no vuelve al centro (cx=%s)" % cx_end)
        ok = False
    if not bs:
        print("TOUCH FALLA: no se detectó en pantalla la fase de freno + dirección simultáneos")
        ok = False
    else:
        if bs_brake < 0.30:
            print("TOUCH FALLA: en la fase de freno + dirección el freno no llega a la pantalla (máx %.4f)" % bs_brake)
            ok = False
        if bs_gas >= 0.30:
            print("TOUCH FALLA: en la fase de freno + dirección el acelerador sigue pisado (máx %.4f)" % bs_gas)
            ok = False
        if cx_idle is None or bs_cx_left < 0 or cx_idle - bs_cx_left < 40:
            print("TOUCH FALLA: el mando no gira al lado contrario mientras se frena (cx=%s, reposo=%s)" % (bs_cx_left, cx_idle))
            ok = False
        if bs_speed < 200:
            print("TOUCH FALLA: frenar y girar a la vez no cambia la velocidad en pantalla")
            ok = False
    if not release:
        print("TOUCH FALLA: no se detectó en pantalla la fase de liberación total de los controles")
        ok = False
    else:
        if release_press >= 0.30:
            print("TOUCH FALLA: tras soltar todo queda presión en algún pedal (máx %.4f)" % release_press)
            ok = False
        if release_cx is None or abs(release_cx - 186) > 14:
            print("TOUCH FALLA: el mando no vuelve al centro tras soltar todo (cx=%s)" % release_cx)
            ok = False
    print("TOUCH PASS=", ok)

    # Hoja de contacto para revisión humana: una fila por fase con el mismo
    # recorte de velocidad y de marcha, en el orden en que ocurrieron.
    vw, vh = REGIONS["velocidad"][2] - REGIONS["velocidad"][0], REGIONS["velocidad"][3] - REGIONS["velocidad"][1]
    mw, mh = REGIONS["marcha"][2] - REGIONS["marcha"][0], REGIONS["marcha"][3] - REGIONS["marcha"][1]
    # Keep a bounded contact sheet: encoders reject extremely wide images when
    # the recording runs at host frame rate (~1100 frames in the emulator).
    rows = (idle, throttle, brake, multi, end, bs, release)
    columns = min(80, max(max(len(phase) for phase in rows), 1))
    sheet = Image.new("RGB", (columns * (vw + mw + 12), len(rows) * (vh + 8)), (12, 16, 20))
    for row, phase in enumerate(rows):
        stride = max(1, len(phase) // columns)
        for column, frame in enumerate(phase[::stride][:columns]):
            x = column * (vw + mw + 12)
            sheet.paste(frame["velocidad"], (x, row * (vh + 8)))
            sheet.paste(frame["marcha"], (x + vw + 4, row * (vh + 8) + (vh - mh) // 2))
    sheet.save(outdir / "fases-velocidad-marcha.jpg", "JPEG", quality=88)
    (outdir / "touch.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("layout"); p.add_argument("png"); p.set_defaults(func=cmd_layout)
    p = sub.add_parser("ready"); p.add_argument("serial"); p.set_defaults(func=cmd_ready)
    p = sub.add_parser("clock"); p.add_argument("serial"); p.add_argument("outdir"); p.set_defaults(func=cmd_clock)
    p = sub.add_parser("touch"); p.add_argument("serial"); p.add_argument("outdir"); p.set_defaults(func=cmd_touch)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
