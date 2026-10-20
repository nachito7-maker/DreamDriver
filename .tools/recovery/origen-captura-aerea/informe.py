#!/usr/bin/env python3
"""Genera el informe autocontenido de la investigación sobre la captura aérea.

Autocontenido a propósito: el panel de vista previa sólo sirve el propio HTML, así
que cada imagen se incrusta como data URI (reducida a 1100 px de ancho) y no hace
falta ningún servidor. No toca ningún archivo del juego.
"""
from __future__ import annotations

import base64
import io
import re
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]

# (ruta, epígrafe, pie)
PANELES: list[tuple[str, str, str]] = [
    (".tools/recovery/origen-captura-aerea/apk-en-ejecucion.png",
     "1. APK actual en el emulador (juego en marcha)",
     "Cámara de persecución del juego: cielo azul arriba, asfalto y césped en el 97 % inferior, coche centrado."),
    (".tools/recovery/revert/shot-apk-recuperado-final.png",
     "2. APK recuperado (23:20, referencia previa a esta investigación)",
     "Misma vista y misma huella que integral/shots/pantalla.png: la compilación no cambió."),
    (".tools/recovery/origen-captura-aerea/crops/coche-marcado-apk-en-ejecucion.png",
     "3. Tamaño del coche en el juego (caja marcada a mano sobre la captura 1)",
     "El coche con el piloto ocupa aproximadamente un 13 % de la altura del lienzo y está centrado en el\nencuadre. La misma medida no se publica para las demás capturas: el detector se infla con la cartelería\nazul del edificio de boxes, así que se verifica a ojo y no se da como cifra."),
    (".tools/recovery/origen-captura-aerea/ventanas/godot-editor.png",
     "4. Editor de Godot con scenes/race.tscn abierto (ventana completa)",
     "El viewport 3D está vacío: la escena sólo contiene un Node3D con el script; el circuito se construye en ejecución."),
    (".tools/recovery/origen-captura-aerea/viewport-godot-editor.png",
     "5. Recorte del viewport 3D del editor (lo que se ve dentro de la vista)",
     "Sin circuito, sin coche, sin cielo: rejilla del editor sobre fondo oscuro."),
    (".tools/recovery/origen-captura-aerea/candidatas/godot-overview.png",
     "6. Captura Unity del MISMO circuito (work/evidence/unity/f1godot, 17:37)",
     "Vista general cenital del GLB importado: sí es aérea y con aspecto de maqueta, pero no hay coche."),
    (".tools/recovery/origen-captura-aerea/candidatas/godot-main-straight.png",
     "7. Captura Unity · recta principal",
     "Cenital a escasa altura sobre el asfalto importado; sin coche en el encuadre."),
    (".tools/recovery/origen-captura-aerea/candidatas/godot-long-right-hander.png",
     "8. Captura Unity · curva rápida derecha",
     "Toma oblicua aérea del trazado."),
    (".tools/recovery/origen-captura-aerea/candidatas/godot-track-limits.png",
     "9. Captura Unity · límites de pista",
     "Toma aérea con los pianos y el asfalto."),
    (".tools/recovery/origen-captura-aerea/candidatas/blender-visual-kn5-top.png",
     "10. Render de Blender del circuito (KN5 visto desde arriba)",
     "Aspecto de maqueta sobre fondo gris; sin coche ni cielo."),
    (".tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/remastered-overview.png",
     "11. Unity · «remastered overview», generado hoy a las 01:49",
     "Vista aérea del MISMO circuito con terreno marrón y tejido urbano: es la imagen con aspecto de maqueta\n"
     "más parecida a la que describes. Vive en el proyecto hermano F1, no en F1Godot."),
    (".tools/recovery/origen-captura-aerea/candidatas-unity-nuevas/six-views-contact-sheet.jpg",
     "12. Unity · hoja de seis vistas aéreas del mismo circuito",
     "Rejilla de vistas cenitales y oblicuas sobre fondo oscuro, servida por HTTP local para revisión\n"
     "(127.0.0.1:8772 y 8089). Ninguna contiene vehículo."),
]


def data_uri(ruta: Path, ancho_max: int = 1100) -> str:
    im = Image.open(ruta).convert("RGB")
    if im.width > ancho_max:
        alto = round(im.height * ancho_max / im.width)
        im = im.resize((ancho_max, alto), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=80, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def panel(ruta: str, titulo: str, pie: str) -> str:
    p = RAIZ / ruta
    if not p.exists():
        return f'<p class="falta">Falta la imagen {ruta}</p>'
    return (
        '<figure><figcaption>%s</figcaption><img src="%s">'
        '<p class="pie">%s</p></figure>' % (titulo, data_uri(p), pie)
    )


def tabla_ventanas() -> str:
    """Inventario de las ventanas de nivel 0 que había abiertas al hacer el diagnóstico."""
    log = AQUI / "ventanas.txt"
    if not log.exists():
        return "<p class=\"falta\">No hay inventario de ventanas.</p>"
    patron = re.compile(r"^#\d+ id=(\d+) capa=(\d+) alfa=([\d.]+)\s+(.+?)\s*\|(.*?)\|\s*(.*)$")
    filas = []
    for linea in log.read_text().splitlines():
        m = patron.match(linea.strip())
        if not m or m.group(2) != "0":
            continue
        _, _, _, propietario, titulo, marco = m.groups()
        filas.append("<tr><th>%s</th><td>%s</td><td>%s</td></tr>"
                     % (propietario, titulo or "(sin título)", marco.strip()))
    return ("<table><thead><tr><th>aplicación</th><th>título de la ventana</th><th>marco</th></tr></thead>"
            "<tbody>%s</tbody></table>" % "".join(filas))


def main() -> int:
    mediciones = ""
    log = AQUI / "mediciones.log"
    if log.exists():
        filas = []
        for linea in log.read_text().splitlines():
            if linea.startswith("--- "):
                actual = linea[4:].strip()
            elif linea.strip().startswith("tamaño="):
                filas.append((actual, linea.strip()))
        for nombre, datos in filas:
            celdas = "".join("<td>%s</td>" % c.split("=", 1)[1]
                             for c in datos.split("  ") if "=" in c)
            mediciones += "<tr><th>%s</th>%s</tr>" % (Path(nombre).name, celdas)
        cabecera = [c.split("=", 1)[0] for c in filas[0][1].split("  ") if "=" in c] if filas else []

    html = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>Origen de la captura aérea — F1 One Shot</title>
<style>
  body { margin:0; background:#0d1014; color:#e9edf3; font:14px/1.5 -apple-system, system-ui, sans-serif; }
  header { padding:20px 22px 6px; }
  h1 { margin:0; font-size:21px; }
  h2 { font-size:16px; color:#9fd0ff; margin:26px 22px 8px; }
  p.intro { margin:6px 22px 0; color:#a9b3c0; max-width:1100px; }
  .rejilla { display:grid; grid-template-columns:repeat(auto-fit,minmax(430px,1fr)); gap:16px; padding:12px 22px 6px; }
  figure { margin:0; background:#151a21; border:1px solid #2b323d; border-radius:9px; overflow:hidden; display:flex; flex-direction:column; }
  figcaption { padding:8px 11px; font-weight:650; font-size:13px; }
  img { display:block; width:100%; height:auto; background:#0b0e12; }
  .pie { margin:0; padding:8px 11px 10px; color:#9aa5b3; font-size:12px; }
  table { border-collapse:collapse; margin:8px 22px 20px; font-size:12px; }
  th, td { border:1px solid #2b323d; padding:4px 7px; text-align:right; }
  th:first-child { text-align:left; font-weight:600; }
  thead th { background:#182029; color:#cfe0ef; }
  .clave { margin:10px 22px 0; padding:12px 14px; border-left:3px solid #58b3ff; background:#121b24; color:#d7e5f2; max-width:1100px; }
  .clave b { color:#fff; }
  .falta { color:#ff9b9b; padding:0 22px; }
  code { background:#1b222b; padding:1px 5px; border-radius:4px; }
</style>
</head>
<body>
<header>
  <h1>¿De dónde salía la vista aérea con aspecto de maqueta?</h1>
  <p class="intro">Investigación sobre el proyecto <code>F1Godot</code> (Godot 4.7.2, Android) el 14-oct-2026.
  No se ha modificado ningún archivo del juego, no se ha reconstruido el circuito y no se ha generado ningún APK nuevo:
  todas las capturas de aplicación son del APK instalado <code>605abf6a…</code>.</p>
</header>

<h2>Lo que dibuja el juego y lo que dibuja el editor</h2>
<div class="rejilla">
  {{JUEGO}}
</div>

<h2>Vistas aéreas que existen en la máquina, pero no son el juego</h2>
<div class="rejilla">
  {{AEREAS}}
</div>

<h2>Medidas comparadas</h2>
<p class="intro">Mismo código de medida para todas las imágenes: <code>.tools/recovery/origen-captura-aerea/medir_vistas.py</code>.
<code>cielo_%</code> es azul clarito y luminoso; <code>oscuro_%</code> es luma &lt; 45;
<code>marron_%</code> exige R&gt;G&gt;B con contraste cálido; <code>calzada_%</code> es gris casi neutro y
luminoso (pista); <code>horizonte_%_alto</code> es la fila del mayor salto de brillo (una vista a ras de suelo lo
deja en la parte de arriba; una cenital, en el centro). En la ventana del editor, <code>calzada_%</code> mide
grises de la propia interfaz, no asfalto: sólo es interpretable en las capturas que son representaciones de la
escena.</p>
<table>
  <thead><tr><th>captura</th>{{CABECERA}}</tr></thead>
  <tbody>{{FILAS}}</tbody>
</table>

<div class="clave">
  <p><b>El viewport del editor no puede ser el origen.</b> <code>scenes/race.tscn</code> tiene 7 líneas: un
  <code>Node3D</code> llamado <code>Race</code> con <code>race.gd</code> y nada más. La pista, el coche, la cámara y
  el cielo se crean en <code>_ready()</code> al ejecutar. Por eso el viewport 3D del editor sale oscuro y vacío
  (82 % de píxeles oscuros, 1,8 % de cielo, 0,1 % de verde) y ninguna captura del editor puede contener el circuito.</p>
</div>

<h2>Lo que había abierto en el escritorio durante el diagnóstico</h2>
<p class="intro">Inventario tomado con <code>winlist</code> (CoreGraphics, sólo lectura) mientras el editor de Godot
estaba abierto. Ninguna ventana del escritorio dibuja el circuito salvo el APK del emulador; la única vista aérea
del circuito que existe en la máquina son las capturas Unity del proyecto hermano.</p>
{{VENTANAS}}
</body>
</html>
"""
    html = (html
            .replace("{{JUEGO}}", "\n".join(panel(*p) for p in PANELES[:5]))
            .replace("{{AEREAS}}", "\n".join(panel(*p) for p in PANELES[5:]))
            .replace("{{CABECERA}}", "".join("<th>%s</th>" % c for c in cabecera))
            .replace("{{FILAS}}", mediciones)
            .replace("{{VENTANAS}}", tabla_ventanas()))

    destino = AQUI / "informe.html"
    destino.write_text(html)
    print("escrito %s (%d KiB)" % (destino, destino.stat().st_size // 1024))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
