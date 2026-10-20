#!/usr/bin/env python3
"""Galería comparativa de la cámara: el antes y el después, a cada velocidad.

Lee los informes de la sonda (`medidas.json`) y de la medida en píxeles
(`pixeles.json`) de `.tools/recovery/fase-camara` (cámara nueva) y de su
subcarpeta `antes` (cámara anterior), y escribe `comparativa.html` con las
capturas emparejadas y la tabla de distancias y tamaños medidos.
"""

from __future__ import annotations

import base64
import html
import io
import json
import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent
ANTES = RAIZ / "antes"
AHORA = RAIZ
# Capturas del teléfono: las deja la comprobación obligatoria de `verify.sh`
# (sección 9), conduciendo con toques reales. Si no existen, no hay sección.
DISPOSITIVO = RAIZ.parent / "integral" / "shots" / "camara"
ORDEN = ["parado", "50", "100", "107", "150", "191", "200",
         "frenada-150", "frenada-100", "frenada-50", "frenado-final", "muro-prueba"]


# Caché de miniaturas: se incrustan en el HTML (base64) para que la galería se
# pueda ver sin servidor de por medio. Las capturas completas (2400x1080, varios
# MB cada una) se quedan en disco y se enlazan desde la propia carpeta.
MINIATURAS: dict[str, str] = {}
ANCHO_MINIATURA = 640


def miniatura(camino: Path) -> str:
    """La imagen, reducida y en base64, para incrustarla en el documento."""
    clave = str(camino)
    if clave not in MINIATURAS:
        with Image.open(camino) as imagen:
            copia = imagen.convert("RGB")
            alto = max(1, round(copia.height * ANCHO_MINIATURA / copia.width))
            copia = copia.resize((ANCHO_MINIATURA, alto), Image.LANCZOS)
            memoria = io.BytesIO()
            copia.save(memoria, format="JPEG", quality=78, optimize=True)
        MINIATURAS[clave] = base64.b64encode(memoria.getvalue()).decode("ascii")
    return "data:image/jpeg;base64," + MINIATURAS[clave]


def leer(directorio: Path) -> tuple[dict, dict]:
    medidas = json.loads((directorio / "medidas.json").read_text())
    pixeles = {}
    archivo = directorio / "pixeles.json"
    if archivo.exists():
        pixeles = json.loads(archivo.read_text())
    return medidas, pixeles


def indexar(medidas: dict) -> dict:
    return {caso["id"]: caso for caso in medidas["casos"]}


def fila(identificador: str, antes: dict, ahora: dict, pix_antes: dict, pix_ahora: dict) -> str:
    a, b = antes.get(identificador), ahora.get(identificador)
    pa = pix_antes.get(identificador, {})
    pb = pix_ahora.get(identificador, {})
    if a is None and b is None:
        return ""
    def celda(caso, pix, campo, formato):
        if caso is None:
            return "<td>—</td>"
        return f"<td>{formato.format(caso[campo])}</td>"
    def celda_px(pix):
        if not pix:
            return "<td>—</td>"
        return f"<td>{pix['pixel_alto_px']} px ({pix['pixel_alto_fraccion'] * 100:.1f} %)</td>"
    etiqueta = html.escape(b["id"] if b else a["id"])
    velocidad = (b or a)["velocidad_kph"]
    return (
        f"<tr><td class='id'>{etiqueta}</td><td>{velocidad:.1f}</td>"
        + celda(a, pa, "distancia_plano_m", "{:.2f} m")
        + celda_px(pa)
        + celda(b, pb, "distancia_plano_m", "{:.2f} m")
        + celda_px(pb)
        + "</tr>"
    )


def capturas(identificador: str) -> str:
    trozos = []
    for etiqueta, directorio, clase in (("antes", ANTES, "a"), ("ahora", AHORA, "b")):
        for sufijo in ("coche", "fondo"):
            camino = directorio / "capturas" / f"{identificador}-{sufijo}.png"
            if camino.exists():
                trozos.append(
                    f"<figure class='{clase}'><img src='{miniatura(camino)}' "
                    f"alt='{etiqueta} {html.escape(identificador)} {sufijo}'>"
                    f"<figcaption>{etiqueta} · {sufijo}</figcaption></figure>")
    if not trozos:
        return ""
    return f"<section><h3>{html.escape(identificador)}</h3><div class='par'>{''.join(trozos)}</div></section>"


def dispositivo() -> str:
    """Tabla y capturas del teléfono, ordenadas por la velocidad del HUD."""
    informe = DISPOSITIVO / "pixeles-dispositivo.json"
    if not informe.exists():
        return ""
    datos = json.loads(informe.read_text())
    filas = []
    for captura in datos.get("capturas", []):
        if captura.get("kmh") is None:
            continue
        filas.append(captura)
    filas.sort(key=lambda f: f["kmh"])
    if not filas:
        return ""
    tabla = ["<tr><th>captura</th><th>km/h</th><th>coche en pantalla</th><th>margen</th></tr>"]
    figuras = []
    equivalencias = {e["archivo"]: e["objetivo_kph"] for e in datos.get("equivalencias", [])}
    for captura in filas:
        camino = DISPOSITIVO / captura["archivo"]
        if not camino.exists():
            continue
        objetivo = equivalencias.get(captura["archivo"])
        etiqueta = f"{captura['kmh']:.1f} km/h" + (f" · objetivo {objetivo:.0f}" if objetivo is not None else "")
        tabla.append(
            f"<tr><td class='id'>{html.escape(captura['archivo'])}</td><td>{captura['kmh']:.1f}</td>"
            f"<td>{captura['alto_px']} px ({captura['alto_fraccion'] * 100:.1f} %)</td>"
            f"<td>{captura['margen_min_px']} px</td></tr>")
        figuras.append(
            f"<figure><img src='{miniatura(camino)}' alt='{html.escape(captura['archivo'])}'>"
            f"<figcaption>{html.escape(etiqueta)}</figcaption></figure>")
    factor = datos.get("factor", 0.0)
    maxima = datos.get("velocidad_maxima_kph")
    cabecera = (
        f"<h2>Cámara en el teléfono, conduciendo con toques reales</h2>\n"
        f"<p>Capturas de <code>{html.escape(str(DISPOSITIVO))}</code>, tomadas por la\n"
        f"comprobación obligatoria de <code>verify.sh</code> mientras se conduce con\n"
        f"<code>input swipe</code> sobre los pedales. La velocidad se lee de la barra del\n"
        f"HUD en la propia imagen. De parado al máximo medido"
        + (f" ({maxima:.1f} km/h)" if maxima else "")
        + f" el coche crece <b>{factor:.2f}×</b>. La silueta del teléfono la saca el\n"
        f"clasificador de librea, no la diferencia con un fotograma sin coche: mide la\n"
        f"tendencia, no el valor absoluto (ver el informe).</p>\n"
        f"<table>{''.join(tabla)}</table>\n"
        f"<div class='par'>{''.join(figuras)}</div>")
    return cabecera


def main() -> int:
    medidas_antes, pixeles_antes = leer(ANTES)
    medidas_ahora, pixeles_ahora = leer(AHORA)
    casos_antes = indexar(medidas_antes)
    casos_ahora = indexar(medidas_ahora)
    pix_antes = {f["id"]: f for f in pixeles_antes.get("filas", [])}
    pix_ahora = {f["id"]: f for f in pixeles_ahora.get("filas", [])}
    identificadores = [i for i in ORDEN if i in casos_antes or i in casos_ahora]
    identificadores += [i for i in casos_ahora if i not in identificadores]

    filas = "".join(fila(i, casos_antes, casos_ahora, pix_antes, pix_ahora) for i in identificadores)
    secciones = "".join(capturas(i) for i in identificadores)
    seccion_dispositivo = dispositivo()
    factor_antes = pixeles_antes.get("factor_pixeles", 0.0)
    factor_ahora = pixeles_ahora.get("factor_pixeles", 0.0)
    documento = f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<title>Cámara de persecución: antes y después</title>
<style>
 body {{ background:#0b1013; color:#e6eef2; font-family:-apple-system,'Segoe UI',sans-serif; margin:24px; }}
 h1 {{ font-size:22px; }} h2 {{ font-size:17px; margin-top:32px; color:#9fd8c2; }}
 h3 {{ font-size:14px; margin:18px 0 6px; color:#c9dde4; font-weight:600; }}
 table {{ border-collapse:collapse; font-size:13px; margin-top:12px; }}
 th,td {{ border:1px solid #24313a; padding:5px 9px; text-align:right; }}
 th {{ background:#16202a; color:#9fd8c2; }}
 td.id {{ text-align:left; color:#ffd479; }}
 .par {{ display:flex; flex-wrap:wrap; gap:10px; }}
 figure {{ margin:0; }}
 img {{ width:520px; border:1px solid #24313a; border-radius:6px; display:block; }}
 figcaption {{ font-size:11px; color:#8fa3ad; padding-top:3px; }}
 p {{ font-size:13px; color:#a9bcc4; max-width:1100px; line-height:1.5; }}
 code {{ background:#16202a; padding:1px 4px; border-radius:3px; }}
</style></head><body>
<h1>Cámara de persecución según la velocidad — antes y después</h1>
<p>Todas las capturas están hechas en el mismo lienzo de 2400 × 1080 (la sonda
dibuja en un SubViewport de ese tamaño, el mismo del teléfono), con el coche a
la misma velocidad y en el mismo punto de la recta inicial. «antes» reproduce la
fórmula que se retiró; «ahora» es la entregada.</p>
<p><b>Medido en píxeles</b> (silueta del coche, diferencia entre el fotograma con
y sin modelo): de parado a 200 km/h el coche pasa de
<b>{factor_antes * 100:.0f} %</b> de su tamaño a <b>{factor_ahora * 100:.0f} %</b>
— es decir, con la cámara anterior se encogía a un
{(1 / factor_antes):.1f}× y ahora crece {(factor_ahora):.2f}×.</p>
<h2>Distancias y tamaños medidos</h2>
<table><thead><tr><th>caso</th><th>km/h</th><th>antes · distancia</th><th>antes · alto en pantalla</th>
<th>ahora · distancia</th><th>ahora · alto en pantalla</th></tr></thead>
<tbody>{filas}</tbody></table>
<h2>Capturas emparejadas</h2>
{secciones}
{seccion_dispositivo}
</body></html>
"""
    destino = RAIZ / "comparativa.html"
    destino.write_text(documento)
    print(f"GALERIA {destino} ({len(identificadores)} casos, factor antes={factor_antes:.2f} ahora={factor_ahora:.2f})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
