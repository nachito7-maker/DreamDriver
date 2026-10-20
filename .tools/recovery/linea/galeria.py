#!/usr/bin/env python3
"""Galería de las capturas de la línea y de la goma de la trazada.

Arma dos cosas, para poder MIRAR lo que se ha medido:

  * `comparativa-goma.png`: el antes y el después de la franja de goma, recortados
    alrededor de las muestras que la propia sonda guardó (`.tools/recovery/linea/
    capturas.json`, `goma_muestras`), ampliados 2× y con el mismo encuadre. Es el
    antes/después de la corrección del tono azulado.
  * `galeria.html`: por caso, el fotograma con la línea y las tres capturas con la
    línea forzada a verde, amarillo y rojo, más el "antes" de la goma. Los números de
    cada caso (estación, velocidad, estados) se leen de los registros.

No comprueba nada: eso lo hace `linea_pixeles.py`. Esto es sólo la vista.

Uso:  python3 .tools/recovery/linea/galeria.py [dir]
"""

from __future__ import annotations

import html
import json
import sys
from pathlib import Path

from PIL import Image

DIR = Path(__file__).resolve().parent
DISPAROS = DIR / "disparos"
ANTES = DIR / "disparos-antes"


def leer_registro(ruta: Path) -> dict:
    return json.loads(ruta.read_text()) if ruta.exists() else {}


def recorte_goma(registro: dict, caja: tuple[int, int, int, int] | None) -> tuple[int, int, int, int]:
    """Caja alrededor de las muestras de goma que guardó la sonda (y la reutiliza)."""
    if caja is not None:
        return caja
    puntos = [m["punto"] for m in registro.get("goma_muestras", []) if not m["punto"].get("detras")]
    if not puntos:
        return (0, 0, 0, 0)
    xs = [float(p["x"]) for p in puntos]
    ys = [float(p["y"]) for p in puntos]
    ancho = 420
    alto = 260
    x0 = max(0, int(min(xs)) - ancho // 3)
    y0 = max(0, int(min(ys)) - alto // 2)
    return (x0, y0, x0 + ancho, y0 + alto)


def comparativa_goma(registro: dict) -> tuple[str, tuple[int, int, int, int]]:
    despues = DISPAROS / "goma-base.png"
    antes = ANTES / "goma-base.png"
    if not despues.exists() or not antes.exists():
        return "", (0, 0, 0, 0)
    caja = recorte_goma(registro, None)
    a = Image.open(antes).convert("RGB").crop(caja).resize(
        ((caja[2] - caja[0]) * 2, (caja[3] - caja[1]) * 2), Image.NEAREST)
    b = Image.open(despues).convert("RGB").crop(caja).resize(
        ((caja[2] - caja[0]) * 2, (caja[3] - caja[1]) * 2), Image.NEAREST)
    hoja = Image.new("RGB", (a.width, a.height * 2 + 40), (24, 24, 26))
    hoja.paste(a, (0, 0))
    hoja.paste(b, (0, a.height + 40))
    hoja.save(DIR / "comparativa-goma.png")
    return "comparativa-goma.png", caja


def galeria_html(registro: dict, registro_antes: dict, caja: tuple[int, int, int, int]) -> None:
    casos = registro.get("casos", [])
    antes_por_id = {c["id"]: c for c in registro_antes.get("casos", [])}
    partes = [
        "<!DOCTYPE html><html lang='es'><head><meta charset='utf-8'>",
        "<title>Línea de asistencia y goma de la trazada</title>",
        "<style>body{background:#14161a;color:#e8e8e8;font:15px/1.5 -apple-system,Segoe UI,sans-serif;margin:24px}",
        "h1{font-size:22px}h2{font-size:18px;margin-top:32px}img{max-width:100%;border:1px solid #333;border-radius:4px}",
        ".par{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:8px 0}",
        "code{background:#22262e;padding:1px 5px;border-radius:3px}",
        "table{border-collapse:collapse;margin:8px 0}td,th{border:1px solid #333;padding:4px 8px;font-size:13px}</style>",
        "</head><body>",
        "<h1>Línea dinámica de asistencia y goma de la trazada</h1>",
        f"<p>Lienzo {registro.get('lienzo')}; modo <code>{html.escape(str(registro.get('modo')))}</code>; "
        f"escala de grises de la goma <code>{html.escape(str(registro.get('escala_de_grises')))}</code>.</p>",
    ]
    if (DIR / "comparativa-goma.png").exists():
        partes.append("<h2>La goma de la trazada: antes (material del GLB) y después (corrección)</h2>")
        partes.append("<p>Mismo encuadre, mismas muestras, ampliado 2×. Recorte "
                      f"<code>{caja}</code>.</p>")
        partes.append("<img src='comparativa-goma.png' alt='antes y después de la goma'>")
    for caso in casos:
        ident = html.escape(caso["id"])
        partes.append(f"<h2>Caso {ident} — patrón {html.escape(str(caso.get('patron')))}</h2>")
        partes.append(
            "<p>Estación <code>%d</code> del arco, <code>%.0f</code> km/h: verdes %d, amarillos %d, rojos %d; "
            "muestras visibles y medibles %d %s (más %d más lejos que 120 m).</p>" % (
                int(caso["indice"]), float(caso["velocidad_kph"]), int(caso["verdes"]),
                int(caso["amarillos"]), int(caso["rojos"]), int(caso["visibles"]),
                html.escape(str(caso.get("visibles_por_estado"))), int(caso.get("visibles_lejos", 0))))
        partes.append("<div class='par'>")
        partes.append(f"<div><img src='disparos/{ident}-linea.png'><p>con la línea</p></div>")
        partes.append(f"<div><img src='disparos/{ident}-base.png'><p>sin la línea (mismo instante)</p></div>")
        partes.append("</div><div class='par'>")
        for color in ("verde", "amarillo", "rojo"):
            ruta = DISPAROS / f"{ident}-forzado-{color}.png"
            if ruta.exists():
                partes.append(f"<div><img src='disparos/{ident}-forzado-{color}.png'><p>forzada a {color}</p></div>")
        partes.append("</div>")
        if ident in antes_por_id:
            previo = ANTES / f"{ident}-base.png"
            if previo.exists():
                partes.append(f"<img src='disparos-antes/{ident}-base.png'><p>el mismo instante con el "
                              "material de goma del GLB (el antes)</p>")
        refs = caso.get("referencias") or {}
        if refs:
            partes.append("<table><tr><th>estado</th><th>rgb medido en esta pose</th><th>muestras</th></tr>")
            for color in ("verde", "amarillo", "rojo"):
                if color in refs:
                    rgb = refs[color]["rgb"]
                    partes.append("<tr><td>%s</td><td>(%.0f, %.0f, %.0f)</td><td>%s</td></tr>" % (
                        color, rgb[0], rgb[1], rgb[2], refs[color].get("n")))
            partes.append("</table>")
    partes.append("</body></html>")
    (DIR / "galeria.html").write_text("\n".join(partes))
    print("LINEA_GALERIA galeria.html y comparativa-goma.png escritos en %s" % DIR)


def main() -> int:
    registro = leer_registro(DIR / "capturas.json")
    registro_antes = leer_registro(DIR / "capturas-antes.json")
    if not registro:
        print("no hay capturas.json: ejecuta antes .tools/recovery/linea/capturar.gd")
        return 1
    _, caja = comparativa_goma(registro)
    galeria_html(registro, registro_antes, caja)
    return 0


if __name__ == "__main__":
    sys.exit(main())
