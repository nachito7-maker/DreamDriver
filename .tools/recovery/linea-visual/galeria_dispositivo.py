#!/usr/bin/env python3
"""Galería para MIRAR la pintura tal y como la dibuja el APK instalado.

Las medidas están en el informe (`INFORME-FASE-LINEA-VISUAL.md`) y en los registros de la
batería; esto es para lo que no se puede medir con un umbral: el juicio estético. Reúne las
capturas del dispositivo (cámara de persecución conduciendo con toques reales, y cámara de
morro), con la fase y la velocidad que el propio juego pintó en el HUD, más las dos hojas de
comparación del anfitrión (antes/después con la misma pose).

    python3 .tools/recovery/linea-visual/galeria_dispositivo.py

Escribe `.tools/recovery/linea-visual/galeria-dispositivo.html`, con rutas relativas: se abre
desde el panel derecho del editor o desde un navegador, sin servidor.
"""

from __future__ import annotations

import base64
import html
import io
import json
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[3]
SALIDA = Path(__file__).resolve().parent / "galeria-dispositivo.html"
# Las imágenes van INCRUSTADAS en el HTML (data URI). El panel del editor sirve el documento y
# sólo el documento: una ruta relativa a otro archivo del proyecto no se resuelve (comprobado:
# 404 en todo lo que no sea el propio HTML). Se reducen a `ANCHO_INCRUSTADO` px y JPEG de
# calidad 90 SIN submuestreo de color, para que el juicio estético no lo haga un artefacto del
# formato; las cuentas se hacen siempre sobre los originales.
ANCHO_INCRUSTADO = 1000
CALIDAD = 90

CARRERA = RAIZ / ".tools/recovery/integral/shots/camara"
MORRO = RAIZ / ".tools/recovery/integral/shots/morro"
ANFITRION = Path(__file__).resolve().parent


def incrustada(ruta: Path) -> str:
    """Devuelve la imagen como data URI reducida (sin pérdida de color en el remuestreo)."""
    with Image.open(ruta) as imagen:
        if imagen.width > ANCHO_INCRUSTADO:
            alto = round(imagen.height * ANCHO_INCRUSTADO / imagen.width)
            imagen = imagen.resize((ANCHO_INCRUSTADO, alto), Image.LANCZOS)
        memoria = io.BytesIO()
        imagen.convert("RGB").save(memoria, format="JPEG", quality=CALIDAD, subsampling=0)
    return "data:image/jpeg;base64," + base64.b64encode(memoria.getvalue()).decode("ascii")


def tarjeta(ruta: Path, titulo: str, pie: str) -> str:
    return (
        '<figure class="tarjeta">'
        f'<img src="{incrustada(ruta)}" alt="{html.escape(titulo)}">'
        f"<figcaption><strong>{html.escape(titulo)}</strong><span>{html.escape(pie)}</span></figcaption>"
        "</figure>"
    )


def main() -> int:
    registro = CARRERA / "capturas.json"
    fases: dict[str, dict] = {}
    if registro.exists():
        for fila in json.loads(registro.read_text()).get("capturas", []):
            fases[fila["archivo"]] = fila

    tarjetas: list[str] = []
    for png in sorted(CARRERA.glob("disp-*.png")):
        meta = fases.get(png.name, {})
        fase = meta.get("fase", "")
        kmh = meta.get("kmh")
        if kmh is None:
            pie = fase
        else:
            pie = f"{fase} · {kmh:.0f} km/h"
        tarjetas.append(tarjeta(png, png.name, pie))

    for png in sorted(MORRO.glob("dispositivo-*.png")):
        tarjetas.append(tarjeta(png, png.name, "cámara de morro / persecución, en el aparato"))

    tarjetas_anfitrion = "".join(
        tarjeta(ANFITRION / nombre, nombre, "recorte antes | después, en el anfitrión")
        for nombre in ("comparativa-recta.png", "comparativa-frenada.png", "comparativa-aproximacion.png", "comparativa-salida.png")
        if (ANFITRION / nombre).exists()
    )

    documento = f"""<!DOCTYPE html>
<html lang="es">
<meta charset="utf-8">
<title>La línea de asistencia, en el APK instalado</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{ margin: 0; padding: 24px 28px 64px; background: #101214; color: #e6e8ea;
         font: 15px/1.55 system-ui, -apple-system, "Segoe UI", sans-serif; }}
  h1 {{ font-size: 22px; margin: 0 0 4px; }}
  h2 {{ font-size: 17px; margin: 36px 0 12px; color: #cfd3d7; }}
  p {{ max-width: 78ch; color: #b8bdc2; }}
  .rejilla {{ display: grid; gap: 16px; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); }}
  .tarjeta {{ margin: 0; background: #191c1f; border: 1px solid #262a2e; border-radius: 10px; overflow: hidden; }}
  .tarjeta img {{ display: block; width: 100%; height: auto; }}
  figcaption {{ padding: 8px 12px 10px; display: flex; gap: 10px; justify-content: space-between;
                align-items: baseline; font-size: 13px; }}
  figcaption span {{ color: #9aa0a6; }}
  code {{ background: #1e2226; padding: 1px 5px; border-radius: 4px; }}
</style>
<h1>La línea de asistencia, en el APK instalado</h1>
<p>Capturas del <strong>dispositivo</strong> (emulador Pixel 9a, lienzo 2424×1080) hechas
conduciendo con <strong>toques reales</strong> sobre los pedales; la velocidad es la que el HUD
del juego pinta en esa captura, no un reloj del anfitrión. La pintura tiene que verse apagada,
mate y pegada a la calzada: sin brillo, sin halo y sin dominar la imagen. Medidas y criterios:
<code>.tools/recovery/linea-visual/INFORME-FASE-LINEA-VISUAL.md</code>.</p>
<p>Las imágenes van <strong>incrustadas y reducidas</strong> (1000 px, JPEG sin submuestreo de
color) para que la página viaje en un solo archivo; los originales están en
<code>.tools/recovery/integral/shots/</code> y <code>.tools/recovery/linea/</code>, y las medidas
se hacen siempre sobre ellos.</p>

<h2>Conduciendo en el aparato (cámara de persecución)</h2>
<div class="rejilla">{''.join(tarjetas)}</div>

<h2>Antes y después en el anfitrión, con la misma pose</h2>
<p>El «antes» es el material del GLB y el «después» el actual, con la misma cámara, la misma luz
y la misma posición del coche (el caso se busca de forma determinista). Cada hoja trae el
recorte del campo cercano y el de la línea a 100-180 m.</p>
<div class="rejilla">{tarjetas_anfitrion}</div>
</html>
"""
    SALIDA.write_text(documento)
    print(f"GALERIA {SALIDA} ({len(tarjetas)} capturas del aparato, 4 hojas del anfitrión, "
          f"{SALIDA.stat().st_size / 1e6:.1f} MB con las imágenes incrustadas)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
