#!/usr/bin/env python3
"""Comprobador EN EL DISPOSITIVO de la línea dinámica de asistencia.

La medida fina de la línea es la del anfitrión (`.tools/recovery/linea/linea_pixeles.py`
sobre las capturas de `capturar.gd`), que compara cada píxel con el color que la propia
línea dice en esa misma pose y tiene el «antes» (el material del GLB) y el «después» en la
misma cámara, luz y pose. Esto comprueba lo que sólo se puede comprobar en el teléfono: que
la pintura viaja en el APK y se dibuja conduciendo con toques reales, y que el asfalto que
la rodea no sale azulado.

Lo que se mide, y por qué se mide así:

  * La banda de CALZADA POR DELANTE del coche: x 0,40..0,60 e y 0,40..0,58 del lienzo. Es
    la zona donde proyecta la trazada con la cámara de persecución del juego y es calzada:
    por debajo de y 0,58 la franja la ocupa el coche. La ventana ancha que se usó primero
    (hasta y 0,85) medía en realidad la carrocería —el Red Bull es azul oscuro— y por eso
    daba «calzada azulada»: medido en el aparato, la carrocería da dominante de azul
    mediana 19/255 y la calzada por delante 2..5/255. La ventana corregida mide asfalto.

  * El VERDE de la línea, con el canal verde dominante, la saturación suficiente y la
    luminancia baja (para no contar el césped, que es claro). En el aparato aparece en la
    banda en TODAS las capturas conduciendo con toques reales (mínimo medido 1180 píxeles
    a 0 km/h en la salida y 1193-1682 píxeles entre 43 y 261 km/h), y no aparece con la
    pintura apagada si el APK no la lleva. El umbral por captura es 60 y se exige en al
    menos el 80 % de las capturas con calzada a la vista.

  * La CALZADA de esa banda: entre los píxeles grises se exige que la dominante de azul
    mediana sea pequeña (≤ 8/255). En el anfitrión la franja de goma del GLB medía 19/255
    de dominante azul y la corregida 4/255; en el aparato la banda de calzada mide 2..5.

El rojo y el ámbar de la línea no se exigen aquí: los bordillos rojos y las escapatorias
dan cuentas altas en cualquier fotograma, así que la presencia de esos dos estados en el
aparato se comprueba MIRANDO las capturas (la galería de `.tools/recovery/linea/galeria.py`)
y, de forma cuantitativa, en el anfitrión.

Sale con código distinto de cero si el verde no aparece conduciendo o si la calzada de la
banda sale azulada.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Banda de calzada POR DELANTE del coche (fracciones del lienzo). Orden: x0, y0, x1, y1.
# Por debajo de y 0,58 la franja la ocupa la carrocería azul del coche, que falsea la
# medida de azul del asfalto (medido: 19/255 la carrocería contra 2..5/255 la calzada).
FRANJA = (0.40, 0.40, 0.60, 0.58)
# Región donde se comprueba la diagnosis de arriba (la carrocería). Se mide y se informa,
# no se exige nada de ella.
FRANJA_COCHE = (0.30, 0.58, 0.70, 0.95)

VERDE_SOBRE_ROJO = 20.0
VERDE_SOBRE_AZUL = 15.0
VERDE_LUM_MAX = 140.0
VERDE_SATURACION_MIN = 0.25

GRIS_SATURACION_MAX = 0.15
GRIS_LUM = (20.0, 120.0)
AZUL_MEDIANA_MAX = 8.0             # dominante mediana de azul del asfalto, sobre 255

VERDE_MIN = 60                     # píxeles de verde de la línea por captura
GRIS_MIN = 500                     # píxeles de calzada para que la medida de azul valga
FRACCION_CON_PINTURA = 0.8         # capturas con calzada a la vista que deben mostrar pintura

fallos: list[str] = []


def ok(texto: str) -> None:
    print("LINEA_DISP PASS " + texto)


def fail(texto: str) -> None:
    print("LINEA_DISP FAIL " + texto)
    fallos.append(texto)


def medir(imagen: np.ndarray, franja: tuple[float, float, float, float]) -> dict:
    alto, ancho = imagen.shape[0], imagen.shape[1]
    x0, y0, x1, y1 = franja
    recorte = imagen[int(alto * y0) : int(alto * y1), int(ancho * x0) : int(ancho * x1)]
    r, g, b = recorte[..., 0], recorte[..., 1], recorte[..., 2]
    mayor = recorte.max(axis=2)
    menor = recorte.min(axis=2)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    saturacion = np.where(mayor > 0.0, (mayor - menor) / np.maximum(mayor, 1.0), 0.0)
    verde = ((g > r + VERDE_SOBRE_ROJO) & (g > b + VERDE_SOBRE_AZUL)
             & (lum < VERDE_LUM_MAX) & (saturacion >= VERDE_SATURACION_MIN))
    gris = (saturacion <= GRIS_SATURACION_MAX) & (lum >= GRIS_LUM[0]) & (lum <= GRIS_LUM[1])
    color = [float(np.median(recorte[..., c][verde])) for c in range(3)] if verde.any() else [float("nan")] * 3
    return {
        "verde": int(verde.sum()),
        "gris": int(gris.sum()),
        "azul_mediana": float(np.median((b - r)[gris])) if gris.any() else float("nan"),
        "color_pintura": color,
        "cromatividad_pintura": (max(color) - min(color)) / 255.0 if verde.any() else float("nan"),
    }


def main() -> int:
    if len(sys.argv) < 2:
        print("uso: linea_dispositivo.py <dir-de-capturas-del-dispositivo>")
        return 1
    directorio = Path(sys.argv[1])
    if not directorio.is_dir():
        print(f"no existe el directorio de capturas: {directorio}")
        return 1
    registro = directorio / "capturas.json"
    fases: dict[str, str] = {}
    velocidades: dict[str, float | None] = {}
    if registro.exists():
        datos = json.loads(registro.read_text())
        for fila in datos.get("capturas", []):
            fases[fila["archivo"]] = fila.get("fase", "")
            velocidades[fila["archivo"]] = fila.get("kmh")
    pngs = sorted(directorio.glob("disp-*.png"))
    if not pngs:
        print(f"no hay capturas disp-*.png en {directorio}")
        return 1
    print(f"LINEA_DISP franja={FRANJA} (calzada por delante del coche) capturas={len(pngs)} dir={directorio}")
    medidas = []
    for png in pngs:
        imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.float64)
        fila = medir(imagen, FRANJA)
        coche = medir(imagen, FRANJA_COCHE)
        fila["archivo"] = png.name
        fila["fase"] = fases.get(png.name, "")
        fila["kmh"] = velocidades.get(png.name)
        fila["azul_coche"] = coche["azul_mediana"]
        medidas.append(fila)
        print("LINEA_DISP %-14s fase=%-13s %6s km/h verde=%5d calzada=%6d azul=%4.1f "
              "pintura=(%3.0f,%3.0f,%3.0f) cromat=%.2f | (carroceria azul=%4.1f)"
              % (fila["archivo"], fila["fase"] or "?",
                 "?" if fila["kmh"] is None else "%.0f" % fila["kmh"],
                 fila["verde"], fila["gris"], fila["azul_mediana"],
                 fila["color_pintura"][0], fila["color_pintura"][1], fila["color_pintura"][2],
                 fila["cromatividad_pintura"], fila["azul_coche"]))

    con_calzada = [m for m in medidas if m["gris"] >= GRIS_MIN]
    if not con_calzada:
        fail("no hay capturas con calzada a la vista para medir la pintura")
    else:
        con_pintura = [m for m in con_calzada if m["verde"] >= VERDE_MIN]
        minimo = min(m["verde"] for m in con_calzada)
        maximo = max(m["verde"] for m in con_calzada)
        exigidas = int(np.ceil(FRACCION_CON_PINTURA * len(con_calzada)))
        if len(con_pintura) >= exigidas:
            ok("la pintura de la línea se ve en el aparato conduciendo con toques reales "
               "(%d de %d capturas con calzada a la vista, mínimo exigido %d; entre %d y %d "
               "píxeles de verde por captura, del reposo a %s km/h)"
               % (len(con_pintura), len(con_calzada), exigidas, minimo, maximo,
                  "%.0f" % max((m["kmh"] or 0) for m in con_calzada)))
        else:
            fail("la pintura de la línea no aparece en el aparato (%d de %d capturas con "
                 "calzada a la vista, mínimo exigido %d; máximo medido %d píxeles)"
                 % (len(con_pintura), len(con_calzada), exigidas, maximo))

        peor = max(con_calzada, key=lambda m: m["azul_mediana"])
        if peor["azul_mediana"] <= AZUL_MEDIANA_MAX:
            ok("la calzada por delante del coche no sale azulada en el aparato (peor dominante "
               "mediana %.1f ≤ %.1f sobre 255, en %d capturas; la carrocería que ocupa la "
               "franja de abajo da %.1f y no se cuenta)"
               % (peor["azul_mediana"], AZUL_MEDIANA_MAX, len(con_calzada), peor["azul_coche"]))
        else:
            fail("la calzada del aparato sale azulada (dominante mediana %.1f > %.1f sobre 255 en %s)"
                 % (peor["azul_mediana"], AZUL_MEDIANA_MAX, peor["archivo"]))

        pintadas = [m for m in con_calzada if m["verde"] >= VERDE_MIN]
        if pintadas:
            cromat = float(np.median([m["cromatividad_pintura"] for m in pintadas]))
            color = [float(np.median([m["color_pintura"][c] for m in pintadas])) for c in range(3)]
            print("LINEA_DISP pintura del aparato: color mediano (%.0f,%.0f,%.0f), cromatividad "
                  "mediana %.2f (el material anterior del GLB pintaba 0,25 en el anfitrión, "
                  "ver .tools/recovery/linea-visual/comparativa.log)"
                  % (color[0], color[1], color[2], cromat))

    print("LINEA_DISP %s comprobaciones=2 fallos=%d" % ("PASS" if not fallos else "FAIL", len(fallos)))
    return 0 if not fallos else 1


if __name__ == "__main__":
    sys.exit(main())
