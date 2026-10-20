"""Hojas de contacto de la entrega de ruedas (fase 2).

Monta, sin retocar ninguna imagen:
  * disparos/hoja-de-contacto.png  — las tres situaciones (parado, recta, curva)
    por los cinco puntos de vista.
  * disparos/zoom-ruedas.png       — ampliación 2x de la rueda trasera izquierda
    en las tres situaciones, que es donde se ve si apoya o flota.
  * disparos/comparativa-antes-despues.png — la misma vista de persecución antes
    de tocar nada, tras corregir la pose y con el estado final.

Uso: python3 .tools/recovery/fase2-ruedas/hoja_contacto.py
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
PHASE = ROOT / ".tools/recovery/fase2-ruedas"
CAPTURES = PHASE / "capturas"
SHOTS = PHASE / "disparos"
VIEWS = ["camara_del_juego", "trasera_baja", "lateral", "tres_cuartos", "frontal",
         "rueda_trasera", "rueda_delantera"]
SITUATIONS = [("parado", "parado sobre el asfalto"), ("recta", "en recta, 206 km/h"),
              ("curva", "en curva, 111 km/h")]
LABEL = {"camara_del_juego": "camara del juego", "trasera_baja": "trasera baja",
         "lateral": "lateral", "tres_cuartos": "tres cuartos", "frontal": "frontal",
         "rueda_trasera": "rueda trasera izq. (primer plano)",
         "rueda_delantera": "rueda delantera izq. (primer plano)"}


def load(path):
    image = Image.open(path).convert("RGB")
    return image


def sheet():
    cell = 440
    rows = []
    for tag, note in SITUATIONS:
        row = []
        for view in VIEWS:
            path = CAPTURES / f"{tag}-{view}.png"
            if not path.exists():
                continue
            image = load(path)
            ratio = cell / image.width
            row.append(image.resize((cell, max(1, round(image.height * ratio))), Image.LANCZOS))
        rows.append((tag, note, row))
    height = sum(r[2][0].height + 26 for r in rows)
    canvas = Image.new("RGB", (cell * len(VIEWS), height), (18, 18, 20))
    draw = ImageDraw.Draw(canvas)
    y = 0
    for tag, note, row in rows:
        draw.text((6, y + 7), f"{tag.upper()} - {note}", fill=(240, 240, 240))
        y += 26
        for i, image in enumerate(row):
            canvas.paste(image, (i * cell, y))
            draw.text((i * cell + 6, y + 6), LABEL[VIEWS[i]], fill=(255, 240, 120))
        y += row[0].height
    canvas.save(SHOTS / "hoja-de-contacto.png")
    print("hoja-de-contacto.png", canvas.size)


def zoom():
    """Primer plano de la rueda trasera izquierda en las tres situaciones. La
    vista la toma la propia sonda desde 2 m a la altura del neumático, así que no
    hay que recortar a ojo: lo que se ve es la goma contra el asfalto."""
    crops = []
    for tag, note in SITUATIONS:
        image = load(CAPTURES / f"{tag}-rueda_trasera.png")
        ratio = 900 / image.width
        crop = image.resize((900, round(image.height * ratio)), Image.LANCZOS)
        crops.append((tag, note, crop))
    width = sum(c[2].width for c in crops)
    height = max(c[2].height for c in crops) + 26
    canvas = Image.new("RGB", (width, height), (18, 18, 20))
    draw = ImageDraw.Draw(canvas)
    x = 0
    for tag, note, crop in crops:
        canvas.paste(crop, (x, 26))
        draw.text((x + 6, 7), f"{tag.upper()} - {note} (2x)", fill=(240, 240, 240))
        x += crop.width
    canvas.save(SHOTS / "zoom-ruedas.png")
    print("zoom-ruedas.png", canvas.size)


def before_after():
    steps = [
        (Path(ROOT / ".tools/wheels/w-chase.jpg"), "ANTES (13:22) - ruedas despegadas y pivote girado"),
        (Path(ROOT / ".tools/wheels/n0-chase.jpg"), "POSE CORREGIDA (13:43) - asset sin reconstruir"),
        (CAPTURES / "parado-camara_del_juego.png", "ENTREGA (14:07) - ruedas apoyadas"),
    ]
    images = []
    for path, note in steps:
        if not path.exists():
            print("falta", path)
            continue
        image = load(path)
        ratio = 1280 / image.width
        images.append((note, image.resize((1280, round(image.height * ratio)), Image.LANCZOS)))
    height = sum(i.height + 26 for _, i in images)
    canvas = Image.new("RGB", (1280, height), (18, 18, 20))
    draw = ImageDraw.Draw(canvas)
    y = 0
    for note, image in images:
        draw.text((6, y + 7), note, fill=(240, 240, 240))
        canvas.paste(image, (0, y + 26))
        y += image.height + 26
    canvas.save(SHOTS / "comparativa-antes-despues.png")
    print("comparativa-antes-despues.png", canvas.size)


def numbers():
    data = json.loads((PHASE / "medidas.json").read_text())
    lines = ["situacion  velocidad  pose(deg)  aire bajo rueda (mm) por rueda"]
    for tag, value in data.items():
        air = " ".join(f"{k}={v['aire_bajo_rueda_m'] * 1000:+.1f}" for k, v in sorted(value["ruedas"].items()))
        lines.append(f"{tag:9s} {value['velocidad_m_s'] * 3.6:7.1f} km/h {value['pose_grados']:6.2f}   {air}")
    (PHASE / "resumen-medidas.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


SHOTS.mkdir(parents=True, exist_ok=True)
sheet()
zoom()
before_after()
numbers()
