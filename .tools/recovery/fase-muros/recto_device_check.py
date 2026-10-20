#!/usr/bin/env python3
"""La maniobra de los dos vídeos, en el APK INSTALADO y con toques reales.

Los dos vídeos del encargo (`9879.mp4` y `9880.mp4`) enseñan un coche que se clava
sobre el asfalto en plena recta: 241,4 → 0,0 km/h en un fotograma en uno y tres
caídas (107,3 → 55,1 y 208,6 → 134,1) en el otro. Este arnés hace esa misma
maniobra en el aparato —acelerador a fondo desde la salida y ni un toque de
dirección— y comprueba, sobre la pantalla del juego:

  * la velocidad que el HUD pinta sube y no se hunde mientras el dedo está puesto
    (un coche clavado contra algo invisible se queda a 0 con el pedal a fondo),
  * la imagen no se congela en ningún intervalo,
  * el coche llega a la velocidad del peor choque de los vídeos (241,4 km/h) sin
    haberse detenido antes sobre la calzada.

Al final deja las capturas, la traza de velocidad, el vídeo de la pantalla
(`screenrecord`) y un informe JSON. La parte que depende de la superficie pisada y
de la estación del trazado la mide el anfitrión (`straight_run_probe.gd` y
`video_replay_probe.gd`); aquí se mide lo que se ve.

    python3 .tools/recovery/fase-muros/recto_device_check.py <serial> <dir-salida>

Sale con código distinto de cero si el coche se clava o si la imagen se congela.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]          # raíz del proyecto
sys.path.insert(0, str(RAIZ / ".tools/recovery"))

from offtrack_device_check import (  # noqa: E402
    ACTIVITY, ADB, BUILD_TOOLS, PKG, PLATFORM_JAR, _app_error, adb, changed_fraction,
)
import camera_pixels  # noqa: E402
import screen_geometry  # noqa: E402

# Los tres choques de los vídeos, en km/h: el peor es el de 9880 (241,4 → 0).
CHOQUES_KPH = [107.3, 208.6, 241.4]
VELOCIDAD_DEL_PEOR_KPH = max(CHOQUES_KPH)
# Mientras el dedo está puesto, quedarse por debajo de esta velocidad después de
# haber rodado de verdad es un clavado: los vídeos acaban a 0,0 y 55,1 km/h.
VELOCIDAD_DE_CLAVADO_KPH = 30.0
# Caída entre dos capturas (2 s) que se INFORMA aunque no suspenda: los vídeos
# pierden el 100 % (241,4 → 0,0) y el 36 % (208,6 → 134,1).
CAIDA_INFORMADA = 0.5
VELOCIDAD_DE_RODADURA_KPH = 100.0
SEGUNDOS_PEDAL = 26.0
INTERVALO_S = 2.0
CONGELADO = 0.01          # fracción de píxeles que cambian entre capturas
VENTANA_PHASE = 25.0


def preparar_inyector(serial: str) -> None:
    java_dir = RAIZ / ".tools/recovery/java-recto"
    dex_dir = RAIZ / ".tools/recovery/dex-recto"
    jar = RAIZ / ".tools/recovery/android-recto.jar"
    java_dir.mkdir(parents=True, exist_ok=True)
    shutil.rmtree(dex_dir, ignore_errors=True)
    dex_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(["javac", "--release", "11", "-classpath", str(PLATFORM_JAR),
                    "-d", str(java_dir), str(RAIZ / ".tools/recovery/AndroidRecto.java")],
                   check=True, capture_output=True, text=True)
    subprocess.run([str(BUILD_TOOLS / "d8"), "--output", str(dex_dir), "--lib", str(PLATFORM_JAR),
                    str(java_dir / "AndroidRecto.class")], check=True, capture_output=True, text=True)
    subprocess.run(["jar", "cf", str(jar), "classes.dex"], cwd=dex_dir,
                   check=True, capture_output=True, text=True)
    subprocess.run([ADB, "-s", serial, "push", str(jar), "/data/local/tmp/android-recto.jar"],
                   check=True, capture_output=True, text=True)


def pantalla(serial: str) -> tuple[int, int]:
    return tuple(screen_geometry.pantalla_de(serial))  # type: ignore[return-value]


def esperar_hud(serial: str, ancho: int, alto: int, intentos: int = 45) -> bool:
    for _ in range(intentos):
        listo = subprocess.run(["python3", str(RAIZ / ".tools/recovery/screen_check.py"), "ready",
                                serial, "--size", f"{ancho}x{alto}"],
                               capture_output=True, text=True,
                               env={**os.environ, "ADB": ADB})
        if listo.returncode == 0:
            return True
        time.sleep(4)
    return False


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    serial, outdir = sys.argv[1], Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    for viejo in list(outdir.glob("*.png")) + list(outdir.glob("*.mp4")):
        viejo.unlink()

    ancho, alto = pantalla(serial)
    geo = screen_geometry.geometria(ancho, alto)
    gas_x, _ = geo["pedal_acelerador_centro"]
    gas_arriba = geo["pedal_arriba_y"]
    print(f"RECTO pantalla {ancho}x{alto} pedal del acelerador x={gas_x:.0f} arriba_y={gas_arriba:.0f}")

    preparar_inyector(serial)
    adb(serial, "shell", "logcat", "-c")
    adb(serial, "shell", "am", "force-stop", PKG)
    time.sleep(2)
    arranque = adb(serial, "shell", "am", "start", "-W", "-n", ACTIVITY)
    print("arranque:", arranque.stdout.strip().splitlines()[-1] if arranque.stdout else arranque.stderr.strip())
    if not esperar_hud(serial, ancho, alto):
        print("RECTO FAIL el juego no dibujó su HUD")
        return 1

    remoto_video = "/sdcard/recto-device.mp4"
    adb(serial, "shell", "rm", "-f", remoto_video)
    # El inyector y el grabador van DESPRENDIDOS de la sesión de adb (`nohup setsid`):
    # si el servidor de adb de este equipo se reinicia a mitad de la maniobra —lo
    # comparten el IDE y el emulador— la sesión cae y el proceso remoto moriría con
    # ella. Comprobado en este emulador: así sobreviven a `adb kill-server`.
    adb(serial, "shell",
        f"nohup setsid sh -c 'screenrecord --time-limit {int(SEGUNDOS_PEDAL) + 6} "
        f"--bit-rate 8000000 --size {ancho}x{alto} {remoto_video}' "
        "</dev/null >/dev/null 2>&1 &", timeout=30.0)
    time.sleep(2)

    remoto_log = "/data/local/tmp/recto.log"
    adb(serial, "shell",
        "nohup setsid sh -c 'CLASSPATH=/data/local/tmp/android-recto.jar app_process /system/bin "
        f"AndroidRecto {gas_x:.0f} {gas_arriba:.0f} {int(SEGUNDOS_PEDAL)} > {remoto_log} 2>&1' "
        "</dev/null >/dev/null 2>&1 &", timeout=30.0)

    capturas: list[Path] = []
    traza: list[dict] = []
    comienzo = time.monotonic()
    while time.monotonic() - comienzo < SEGUNDOS_PEDAL + 4.0:
        instante = round(time.monotonic() - comienzo, 2)
        png = outdir / f"recto-{int(instante):02d}.png"
        with open(png, "wb") as salida:
            captura = subprocess.run([ADB, "-s", serial, "exec-out", "screencap", "-p"],
                                     stdout=salida, timeout=30.0)
        if captura.returncode != 0 or png.stat().st_size < 1000:
            png.unlink(missing_ok=True)
        else:
            barra = camera_pixels.velocidad_de_barra(png)
            capturas.append(png)
            traza.append({"archivo": png.name, "instante_s": instante, "kmh": barra.get("kmh")})
        time.sleep(max(0.0, INTERVALO_S - ((time.monotonic() - comienzo) - instante)))

    registro = ""
    for _ in range(20):
        registro = adb(serial, "shell", "cat", remoto_log).stdout
        if "PHASE fin" in registro:
            break
        time.sleep(1.0)
    (outdir / "recto-android.log").write_text(registro, encoding="utf-8")
    logcat = adb(serial, "shell", "logcat", "-d").stdout
    (outdir / "logcat.txt").write_text(logcat, encoding="utf-8")
    adb(serial, "pull", remoto_video, str(outdir / "recto-device.mp4"), timeout=120.0)

    # Intervalos entre capturas consecutivas: un coche que rueda cambia la escena
    # (la cámara de persecución lo sigue); uno clavado la deja congelada. Fuera de la
    # VENTANA DE RODADURA no se juzga: al arrancar el coche está parado con el dedo
    # aún sin pisar y la imagen no cambia, y después de salirse de la pista también
    # puede pararse, que es lo que hace un coche que se sale a la arena.
    intervalos = [{"a": a["archivo"], "b": b["archivo"], "t_a": a["instante_s"],
                   "t_b": b["instante_s"], "cambio": round(changed_fraction(p, q), 4)}
                  for p, q, a, b in zip(capturas, capturas[1:], traza, traza[1:])]
    velocidades = [f["kmh"] for f in traza if f["kmh"] is not None]
    pico = max(velocidades) if velocidades else None
    # La maniobra termina cuando el dedo se levanta; a partir de ahí el coche puede
    # salirse y frenar en la arena, que es conducción y no un clavado.
    dentro = [f for f in traza if f["kmh"] is not None and f["instante_s"] <= SEGUNDOS_PEDAL]
    alcanzados = [c for c in CHOQUES_KPH if pico is not None and pico >= c]
    # Ventana de rodadura: desde la primera captura en la que el coche ya va lanzado
    # hasta el pico de velocidad (después de cruzarlo, detenerse es salirse).
    rodando = [f for f in dentro if f["kmh"] is not None and f["kmh"] >= VELOCIDAD_DE_CLAVADO_KPH]
    t_inicio = rodando[0]["instante_s"] if rodando else None
    t_pico = max((f["instante_s"] for f in dentro if f["kmh"] is not None
                  and pico is not None and f["kmh"] >= pico), default=None)
    ventana = [i for i in intervalos if t_inicio is not None and t_pico is not None
               and i["t_a"] >= t_inicio and i["t_b"] <= t_pico]
    # El defecto de los vídeos: el coche se queda CLAVADO sobre la calzada antes de
    # llegar a la velocidad a la que ellos se clavaron (9880: 241,4 → 0,0; 9879:
    # 208,6 → 134,1 y 107,3 → 55,1). Se exige cruzarlas todas sin bajar de 30 km/h.
    clavados = []
    lanzado = False
    for fila in dentro:
        if fila["kmh"] >= VELOCIDAD_DE_RODADURA_KPH:
            lanzado = True
        elif lanzado and fila["kmh"] < VELOCIDAD_DE_CLAVADO_KPH:
            clavados.append(fila)
            break
        if fila["kmh"] >= VELOCIDAD_DEL_PEOR_KPH:
            break
    caidas = [a["kmh"] - b["kmh"] for a, b in zip(traza, traza[1:])
              if a["kmh"] is not None and b["kmh"] is not None and b["instante_s"] <= SEGUNDOS_PEDAL]
    mayor_caida = round(max(caidas), 1) if caidas else None
    caidas_grandes = [{"de": a["kmh"], "a": b["kmh"], "instante_s": b["instante_s"]}
                      for a, b in zip(traza, traza[1:])
                      if a["kmh"] is not None and b["kmh"] is not None
                      and b["instante_s"] <= SEGUNDOS_PEDAL
                      and b["kmh"] < a["kmh"] * CAIDA_INFORMADA]
    congelados = [i for i in ventana if i["cambio"] < CONGELADO]
    errores = [linea for linea in logcat.splitlines() if _app_error(linea)]

    informe = {
        "serial": serial,
        "lienzo": [ancho, alto],
        "pedal": {"x": round(gas_x, 1), "arriba_y": round(gas_arriba, 1)},
        "segundos_con_el_pedal_puesto": SEGUNDOS_PEDAL,
        "fases": [linea.strip() for linea in registro.splitlines() if linea.startswith("PHASE")],
        "capturas": len(capturas),
        "traza": traza,
        "intervalos": intervalos,
        "velocidad_maxima_kph": pico,
        "choques_de_los_videos_kph": CHOQUES_KPH,
        "choques_alcanzados_kph": alcanzados,
        "clavados": clavados,
        "ventana_de_rodadura_s": [t_inicio, t_pico],
        "mayor_caida_en_2_s_kph": mayor_caida,
        "caidas_informadas": caidas_grandes,
        "intervalos_congelados": congelados,
        "video": str(outdir / "recto-device.mp4"),
        "errores_logcat": errores[:20],
    }
    (outdir / "recto.json").write_text(json.dumps(informe, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"RECTO capturas={len(capturas)} velocidad máxima={pico} km/h "
          f"(el peor choque de los vídeos es {VELOCIDAD_DEL_PEOR_KPH} km/h) "
          f"mayor caída entre capturas {mayor_caida} km/h")
    for fila in traza:
        print(f"RECTO {fila['instante_s']:5.1f} s  {fila['kmh']} km/h")
    if not capturas or pico is None:
        print("RECTO FAIL no se pudo leer la velocidad de la pantalla")
        return 1
    if errores:
        print(f"RECTO FAIL errores en el registro del dispositivo ({len(errores)}), "
              f"primero: {errores[0][:160]}")
        return 1
    if "PHASE fin" not in registro:
        print("RECTO FAIL la maniobra no llegó a terminar; registro: "
              + " | ".join(registro.splitlines()[-3:]))
        return 1
    if len(alcanzados) < len(CHOQUES_KPH):
        print(f"RECTO FAIL el coche no llega a las velocidades de los choques de los vídeos "
              f"({CHOQUES_KPH} km/h): se quedó en {pico} km/h")
        return 1
    if clavados:
        print(f"RECTO FAIL el coche se clava antes de llegar a la velocidad de los choques: "
              + ", ".join(f"{h['instante_s']} s a {h['kmh']} km/h tras rodar" for h in clavados))
        return 1
    if congelados:
        print(f"RECTO FAIL la imagen se congela con el coche rodando en {len(congelados)} "
              f"intervalos: " + ", ".join(f"{c['a']}->{c['b']}" for c in congelados))
        return 1
    cambios = [i["cambio"] for i in ventana] or [i["cambio"] for i in intervalos]
    print(f"RECTO PASS el coche sube a {pico} km/h con el pedal a fondo y sin dirección, "
          f"cruzando las tres velocidades de los choques de los vídeos sin clavarse "
          f"({len(ventana)} intervalos con el coche rodando, cambio mínimo {min(cambios):.3f})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
