#!/usr/bin/env python3
"""Comparativa ANTES / DESPUÉS de la pintura de la línea de asistencia.

Trabaja sobre las capturas que hace `.tools/recovery/linea/capturar.gd` en las dos
versiones del código (la pintura anterior y la nueva), que son el MISMO caso, la misma
pose y la misma luz, con la línea dibujada y oculta:

  * `comparativa.html` y `comparativa-<caso>.png`: el recorte de la calzada CERCA del
    coche (donde la pintura se ve entera) y el de la línea A DISTANCIA, antes y después,
    con el mismo encuadre cuando la estación elegida coincide.
  * La tabla de los TRES COLORES de referencia medidos por la propia sonda en cada
    pose (`capturas.json`, campo `referencias`): es el color que el motor pinta de
    verdad, con luz y tonemap, en el mismo punto de la pantalla. De ahí salen la
    cromaticidad (máx − mín)/255, el pico de canal y la distancia entre estados, que son
    exactamente los criterios que audita `linea_pixeles.py`.
  * La medida de la PINTURA en el campo cercano: el color mediano de los píxeles que
    cambian al ocultar la línea, el del asfalto que la rodea, y la ORLA (los píxeles que
    cambian fuera del listón): un borde luminoso o un halo aparecería en ese número.

Uso:  python3 .tools/recovery/linea-visual/comparar.py [antes] [despues]
      (por defecto `.tools/recovery/linea-visual/antes` y `.tools/recovery/linea`)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

DIR = Path(__file__).resolve().parent
CASOS = ["recta", "aproximacion", "frenada", "salida"]
COLORES = ["verde", "amarillo", "rojo"]
PESO = np.array([2.0, 4.0, 3.0])
CERCANO_M = 60.0               # estaciones que cuentan como "campo cercano"
DIFERENCIA_PINTURA = 40.0      # cambio mínimo por canal para contar un píxel de pintura
DIFERENCIA_ORLA = 12.0         # cambio mínimo por canal fuera del listón (halo)
ORLA_PX = 4                    # a cuántos píxeles del borde se busca la orla
ORLA_LEJOS_PX = 12             # y más lejos: el desvío tiene que caer a cero ahí


def leer(ruta: Path) -> np.ndarray:
    return np.asarray(Image.open(ruta).convert("RGB")).astype(np.float64)


def fotos(base: Path) -> Path:
    return base if (base / "recta-linea.png").exists() else base / "disparos"


def distancia(a, b) -> float:
    d = (np.asarray(a, dtype=float) - np.asarray(b, dtype=float)) * PESO
    return float(np.sqrt((d * d).sum()))


def cromaticidad(color) -> float:
    return float((max(color) - min(color)) / 255.0)


def luminancia(color) -> float:
    return float(0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2])


def caja_de(puntos: list[dict], margen: tuple[int, int], alto: int, ancho: int) -> tuple | None:
    if not puntos:
        return None
    xs = [float(p["x"]) for p in puntos]
    ys = [float(p["y"]) for p in puntos]
    return (max(0, int(min(xs)) - margen[0]), max(0, int(min(ys)) - margen[1]),
            min(ancho, int(max(xs)) + margen[0]), min(alto, int(max(ys)) + margen[1]))


def recorte(imagen: np.ndarray, caja, zoom: int, etiqueta: str) -> Image.Image:
    x0, y0, x1, y1 = caja
    trozo = Image.fromarray(imagen[y0:y1, x0:x1].astype(np.uint8))
    trozo = trozo.resize(((x1 - x0) * zoom, (y1 - y0) * zoom), Image.NEAREST)
    marco = Image.new("RGB", (trozo.width, trozo.height + 22), (18, 18, 20))
    marco.paste(trozo, (0, 22))
    ImageDraw.Draw(marco).text((6, 6), etiqueta, fill=(235, 235, 235))
    return marco


def medir_cerca(caso: dict, dir_fotos: Path) -> dict | None:
    con_ruta = dir_fotos / f"{caso['id']}-linea.png"
    sin_ruta = dir_fotos / f"{caso['id']}-base.png"
    if not con_ruta.exists() or not sin_ruta.exists():
        return None
    con, base = leer(con_ruta), leer(sin_ruta)
    alto, ancho = con.shape[0], con.shape[1]
    cercanos = [m["punto"] for m in caso["muestras"]
                if not m["ocluido"] and not m.get("mixta") and float(m["ds"]) <= CERCANO_M
                and not m["punto"].get("detras")]
    if not cercanos:
        cercanos = [m["punto"] for m in caso["muestras"] if not m["ocluido"]
                    and not m["punto"].get("detras")]
    caja = caja_de(cercanos, (120, 60), alto, ancho)
    if caja is None:
        return None
    x0, y0, x1, y1 = caja
    a = con[y0:y1, x0:x1]
    b = base[y0:y1, x0:x1]
    dif = np.abs(a - b).max(axis=2)
    mascara = dif > DIFERENCIA_PINTURA
    if int(mascara.sum()) < 50:
        return {"caja": caja, "pintura": None, "fotos": (con, base),
                "cercanos": cercanos, "caso": caso}
    pintura = np.median(a[mascara], axis=0)
    # La orla: el anillo de píxeles justo por fuera del listón. Se mide su color MEDIANO
    # en los dos fotogramas, no cuántos píxeles cambian: entre dos capturas del mismo
    # estado el antialiasing temporal mueve bordes de la escena unos niveles, y contar
    # píxeles cambiaría con ese ruido. Un halo o un borde luminoso, en cambio, movería la
    # MEDIANA del anillo (oscureciéndolo o aclarándolo) en todos sus píxeles.
    def desvio_del_anillo(distancia_px: int) -> tuple[float, np.ndarray, int]:
        anillo = np.zeros_like(mascara)
        for eje in (0, 1):
            for signo in (-1, 1):
                anillo |= np.roll(mascara, signo * distancia_px, axis=eje)
        anillo &= ~mascara
        if int(anillo.sum()) < 20:
            return 0.0, np.array([0.0, 0.0, 0.0]), int(anillo.sum())
        return (float(np.abs(np.median(a[anillo], axis=0) - np.median(b[anillo], axis=0)).max()),
                np.median(b[anillo], axis=0), int(anillo.sum()))

    orla, asfalto, orla_px = desvio_del_anillo(ORLA_PX)
    orla_lejos, _, _ = desvio_del_anillo(ORLA_LEJOS_PX)
    return {
        "caja": caja, "pintura": pintura, "asfalto": asfalto,
        "orla": orla, "orla_lejos": orla_lejos, "orla_px": orla_px,
        "pintura_px": int(mascara.sum()), "fotos": (con, base),
        "cercanos": cercanos, "caso": caso,
    }


def medir_borde(caso: dict, dir_fotos: Path) -> dict | None:
    """Ancho de la TRANSICIÓN del borde, en metros, sobre los cortes transversales.

    Cada corte pautado de la sonda cruza la calzada lado a lado cada 0,1 m. Para cada
    muestra se mide cuánto cambia el píxel al ocultar la línea: dentro de la pintura el
    cambio es el máximo del corte, en el asfalto de al lado es cero, y entre los dos está
    la transición del borde (el antialiasing de un borde duro, o la fusión de la pintura
    desgastada). Se informa la mediana del ancho de transición de los dos lados.
    """
    con_ruta = dir_fotos / f"{caso['id']}-linea.png"
    sin_ruta = dir_fotos / f"{caso['id']}-base.png"
    if not con_ruta.exists() or not sin_ruta.exists():
        return None
    con, base = leer(con_ruta), leer(sin_ruta)
    anchos = []
    for muestra in caso["muestras"]:
        corte = muestra.get("cruce")
        if not corte:
            continue
        perfil = []
        for punto in corte:
            a = medir_pixel(con, punto["punto"])
            b = medir_pixel(base, punto["punto"])
            if a is None or b is None:
                continue
            perfil.append((float(punto["lado"]), float(np.abs(a - b).max())))
        if len(perfil) < 8:
            continue
        tope = max(v for _, v in perfil)
        if tope < 60.0:
            continue
        for sentido in (1.0, -1.0):
            lados = [l for l, _ in perfil if l * sentido >= 0.0]
            valores = {l: v for l, v in perfil if l * sentido >= 0.0}
            transicion = [l for l in sorted(lados, key=lambda l: l * sentido)
                          if 0.15 * tope < valores[l] < 0.85 * tope]
            if transicion:
                anchos.append(round(float(len(transicion)) * 0.1, 2))
    if not anchos:
        return None
    return {"transicion_m": float(np.median(anchos)), "cortes": len(anchos)}


def medir_pixel(imagen: np.ndarray, punto: dict) -> np.ndarray | None:
    if punto.get("detras"):
        return None
    x, y = int(round(float(punto["x"]))), int(round(float(punto["y"])))
    alto, ancho = imagen.shape[0], imagen.shape[1]
    if x < 0 or y < 0 or x >= ancho or y >= alto:
        return None
    return imagen[y, x]


def main() -> int:
    antes_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DIR / "antes"
    despues_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else DIR.parent / "linea"
    for d in (antes_dir, despues_dir):
        if not (d / "capturas.json").exists():
            print(f"falta el registro de capturas en {d}")
            return 1
    antes_por_id = {c["id"]: c for c in json.loads((antes_dir / "capturas.json").read_text())["casos"]}
    despues_por_id = {c["id"]: c for c in json.loads((despues_dir / "capturas.json").read_text())["casos"]}
    fa, fd = fotos(antes_dir), fotos(despues_dir)

    # --- los tres colores medidos por la sonda, antes y después ----------------
    print("COLORES medidos en pantalla en la MISMA pose (media de las muestras pautadas)")
    print("%-13s %-9s %-18s %-18s %-18s %8s %6s" % (
        "caso", "medida", "verde", "amarillo", "rojo", "cromat", "pico"))
    tabla_color = []
    for ident in CASOS:
        refs_antes = (antes_por_id.get(ident) or {}).get("referencias") or {}
        refs_despues = (despues_por_id.get(ident) or {}).get("referencias") or {}
        for etiqueta, refs in (("ANTES", refs_antes), ("DESPUES", refs_despues)):
            if len(refs) < 3:
                continue
            rgb = {c: np.array(refs[c]["rgb"], dtype=float) for c in COLORES}
            peor_cromat = max(cromaticidad(rgb[c]) for c in COLORES)
            pico = max(float(rgb[c].max()) for c in COLORES)
            peor_dist = min((distancia(rgb[a], rgb[b]), a, b)
                            for i, a in enumerate(COLORES) for b in COLORES[i + 1:])
            tabla_color.append({
                "caso": ident, "medida": etiqueta,
                "rgb": {c: [float(v) for v in rgb[c]] for c in COLORES},
                "cromaticidad": peor_cromat, "pico": pico,
                "distancia": peor_dist[0], "par": f"{peor_dist[1]}/{peor_dist[2]}",
            })
            print("%-13s %-9s (%3.0f,%3.0f,%3.0f)    (%3.0f,%3.0f,%3.0f)    (%3.0f,%3.0f,%3.0f) %8.2f %6.0f" % (
                ident, etiqueta, *rgb["verde"], *rgb["amarillo"], *rgb["rojo"], peor_cromat, pico))

    # --- el borde ---------------------------------------------------------
    print("\nBORDE: ancho de la transición del canto, en metros (mediana de los cortes pautados)")
    tabla_borde = []
    for ident in CASOS:
        fila = {"caso": ident}
        for etiqueta, caso, dir_fotos in (("ANTES", antes_por_id.get(ident), fa),
                                          ("DESPUES", despues_por_id.get(ident), fd)):
            dato = medir_borde(caso, dir_fotos) if caso else None
            fila[etiqueta] = dato["transicion_m"] if dato else None
            fila[etiqueta + "_cortes"] = dato["cortes"] if dato else 0
            print("BORDE %-13s %-8s %s" % (ident, etiqueta,
                  "< 0,10 m (de un pixel: ningun corte con pintura a medias)" if not dato
                  else "%.2f m (%d cortes)" % (dato["transicion_m"], dato["cortes"])))
        tabla_borde.append(fila)

    # --- la pintura en el campo cercano ---------------------------------------
    print("\nPINTURA en el campo cercano (pixeles que cambian al ocultar la linea)")
    print("%-13s %-9s %-18s %-18s %8s %10s %10s" % (
        "caso", "medida", "pintura", "asfalto al lado", "px", "orla 4px", "orla 12px"))
    medidas = {}
    tabla_cerca = []
    for ident in CASOS:
        filas = {}
        for etiqueta, caso, dir_fotos in (("ANTES", antes_por_id.get(ident), fa),
                                          ("DESPUES", despues_por_id.get(ident), fd)):
            dato = medir_cerca(caso, dir_fotos) if caso else None
            filas[etiqueta] = dato
            if not dato:
                continue
            if dato["pintura"] is not None:
                print("%-13s %-9s (%3.0f,%3.0f,%3.0f)     (%3.0f,%3.0f,%3.0f)     %8d %10.1f %10.1f" % (
                    ident, etiqueta, *dato["pintura"], *dato["asfalto"], dato["pintura_px"],
                    dato["orla"], dato["orla_lejos"]))
                tabla_cerca.append({
                    "caso": ident, "medida": etiqueta,
                    "pintura": [float(v) for v in dato["pintura"]],
                    "asfalto": [float(v) for v in dato["asfalto"]],
                    "cromaticidad": cromaticidad(dato["pintura"]),
                    "pico": float(max(dato["pintura"])),
                    "luminancia": luminancia(dato["pintura"]),
                    "orla": dato["orla"], "orla_lejos": dato["orla_lejos"],
                    "px": dato["pintura_px"],
                    "ds": round(float(filas[etiqueta]["cercanos"][0]["x"]), 1),
                })
            else:
                print("%-13s %-9s (sin pintura medible en el campo cercano de esta pose)" % (ident, etiqueta))
        medidas[ident] = filas

        # --- la hoja de imágenes: el mismo encuadre antes y después ------------
        piezas = []
        for etiqueta, dato in (("ANTES", filas.get("ANTES")), ("DESPUES", filas.get("DESPUES"))):
            if not dato:
                continue
            piezas.append(recorte(dato["fotos"][0], dato["caja"], 2, f"{etiqueta} - calzada cerca del coche (2x)"))
        for etiqueta, dato in (("ANTES", filas.get("ANTES")), ("DESPUES", filas.get("DESPUES"))):
            if not dato:
                continue
            ancho, alto = dato["fotos"][0].shape[1], dato["fotos"][0].shape[0]
            lejanos = [m["punto"] for m in dato["caso"]["muestras"]
                       if not m["ocluido"] and not m.get("mixta")
                       and 100.0 <= float(m["ds"]) <= 180.0 and not m["punto"].get("detras")]
            caja = caja_de(lejanos, (200, 70), alto, ancho)
            if caja:
                piezas.append(recorte(dato["fotos"][0], caja, 3, f"{etiqueta} - la linea a 100-180 m (3x)"))
        if piezas:
            ancho = max(p.width for p in piezas)
            lienzo = Image.new("RGB", (ancho, sum(p.height for p in piezas) + 9 * (len(piezas) - 1)), (18, 18, 20))
            y = 0
            for p in piezas:
                lienzo.paste(p, (0, y))
                y += p.height + 9
            lienzo.save(DIR / f"comparativa-{ident}.png")

    # --- la página ------------------------------------------------------------
    partes = [
        "<!DOCTYPE html><html lang='es'><head><meta charset='utf-8'>",
        "<title>Pintura de la linea de asistencia: antes y despues</title>",
        "<style>body{background:#14161a;color:#e8e8e8;font:15px/1.55 -apple-system,Segoe UI,sans-serif;margin:24px}",
        "h1{font-size:22px}h2{font-size:18px;margin-top:34px}img{max-width:100%;border:1px solid #333;border-radius:4px}",
        "table{border-collapse:collapse;margin:10px 0}td,th{border:1px solid #333;padding:4px 8px;font-size:13px}",
        "code{background:#22262e;padding:1px 5px;border-radius:3px}.n{color:#8ec07c;font-weight:600}</style></head><body>",
        "<h1>La pintura de la linea de asistencia: antes y despues</h1>",
        "<p>Lienzo 2400x1080, camara de persecucion del juego, misma luz y misma pose: cada recorte es el mismo "
        "encuadre con la pintura vieja (arriba) y con la nueva (abajo). En <code>salida</code> la estacion elegida "
        "es otra (el patron se cumple en varias poses), asi que su encuadre no coincide.</p>",
        "<h2>Los tres colores, medidos en pantalla</h2>",
        "<p>Es el color que el motor PINTA, con su luz y su tonemap, medido por la propia sonda en los pixeles "
        "pautados de cada pose. <b>Cromaticidad</b> = (maximo &minus; minimo)/255, la medida de estridencia que "
        "audita <code>linea_pixeles.py</code> (tope 0,78); <b>pico</b> es el canal mas alto (tope 238); "
        "<b>distancia</b> es la separacion ponderada entre los dos estados mas parecidos (minimo 45).</p>",
        "<table><tr><th>caso</th><th>medida</th><th>verde</th><th>amarillo</th><th>rojo</th>"
        "<th>cromaticidad</th><th>pico</th><th>par mas parecido</th><th>distancia</th></tr>",
    ]
    for fila in tabla_color:
        clase = " class='n'" if fila["medida"] == "DESPUES" else ""
        partes.append("<tr%s><td>%s</td><td>%s</td><td>(%.0f, %.0f, %.0f)</td><td>(%.0f, %.0f, %.0f)</td>"
                      "<td>(%.0f, %.0f, %.0f)</td><td>%.2f</td><td>%.0f</td><td>%s</td><td>%.0f</td></tr>" % (
                          clase, fila["caso"], fila["medida"], *fila["rgb"]["verde"], *fila["rgb"]["amarillo"],
                          *fila["rgb"]["rojo"], fila["cromaticidad"], fila["pico"], fila["par"], fila["distancia"]))
    partes.append("</table>")
    partes.append("<h2>El borde</h2>")
    partes.append("<p>Ancho de la transicion del canto, medido sobre los cortes transversales pautados de cada "
                  "pose: los metros que tarda el pixel en pasar del asfalto a la pintura entera. Un borde de "
                  "pegatina es una linea recta de un pixel (por eso el antes sale &laquo;&lt; 0,10 m&raquo;: ninguna "
                  "muestra del corte llega a medio camino); una pintura desgastada se funde en la superficie.</p>")
    partes.append("<table><tr><th>caso</th><th>antes</th><th>despues</th></tr>")
    for fila in tabla_borde:
        def texto(valor: float | None) -> str:
            # Sin ninguna muestra a medio camino entre el asfalto y la pintura, la
            # transición es más estrecha que el paso de muestreo (0,1 m): borde de un píxel.
            return "&lt; 0,10 m" if valor is None else "%.2f m" % valor
        partes.append("<tr><td>%s</td><td>%s</td><td class='n'>%s</td></tr>" % (
            fila["caso"], texto(fila["ANTES"]), texto(fila["DESPUES"])))
    partes.append("</table>")
    partes.append("<h2>La pintura de cerca</h2>")
    partes.append("<p>Color mediano de los pixeles que cambian al ocultar la linea en el campo cercano (hasta 60 m), "
                  "el del asfalto que la rodea y la <b>orla</b>: cuanto mueve la linea el color mediano del anillo de "
                  "pixeles que quedan justo por fuera de ella (sobre 255). Un halo o un borde luminoso lo moveria; "
                  "el ruido de fotograma a fotograma del antialiasing temporal, al ir por pixeles sueltos, no.</p>")
    partes.append("<table><tr><th>caso</th><th>medida</th><th>pintura</th><th>asfalto</th><th>cromaticidad</th>"
                  "<th>pico</th><th>luminancia</th><th>pixeles</th><th>orla a 4 px</th><th>orla a 12 px</th></tr>")
    for fila in tabla_cerca:
        clase = " class='n'" if fila["medida"] == "DESPUES" else ""
        partes.append("<tr%s><td>%s</td><td>%s</td><td>(%.0f, %.0f, %.0f)</td><td>(%.0f, %.0f, %.0f)</td>"
                      "<td>%.2f</td><td>%.0f</td><td>%.0f</td><td>%d</td><td>%.1f</td><td>%.1f</td></tr>" % (
                          clase, fila["caso"], fila["medida"], *fila["pintura"], *fila["asfalto"],
                          fila["cromaticidad"], fila["pico"], fila["luminancia"], fila["px"],
                          fila["orla"], fila["orla_lejos"]))
    partes.append("</table>")
    for ident in CASOS:
        ruta = DIR / f"comparativa-{ident}.png"
        if ruta.exists():
            partes.append(f"<h2>{ident}</h2><img src='{ruta.name}' alt='{ident}'>")
    partes.append("</body></html>")
    (DIR / "comparativa.html").write_text("\n".join(partes))
    (DIR / "comparativa-datos.json").write_text(json.dumps(
        {"colores": tabla_color, "cerca": tabla_cerca, "borde": tabla_borde}, indent=2))
    print("\nCOMPARAR escrito %s" % (DIR / "comparativa.html"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
