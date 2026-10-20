#!/usr/bin/env python3
"""Mide EN PÍXELES la línea dinámica de asistencia sobre las capturas de
`.tools/recovery/linea/capturar.gd`.

La sonda `scripts/driving_line_probe.gd` comprueba las cuentas (velocidad ideal,
envolventes, punto de frenada, la vuelta conducida). Esta comprobación no usa
ninguna de esas cuentas: abre los PNG y mide lo que hay pintado.

Cómo se mide, sin suponer ningún color de antemano:

  * Por caso se guardan tres capturas `disparos/<caso>-forzado-<color>.png`: la
    MISMA pose, la MISMA velocidad y el MISMO sitio de la pantalla con la línea
    forzada a un solo color. De ahí salen los tres colores tal como los pinta el
    motor ahí (luz y tonemap incluidos). Se miden por caso y no una vez para toda
    la vuelta porque la exposición no es la misma en todas las poses: medido, el
    verde de la recta sale (31,96,41) y en la salida de la horquilla (2,84,12)
    sobre el mismo material, así que una referencia tomada en otro sitio
    clasificaba mal los píxeles de este.
  * Cada caso tiene `<caso>-linea.png` (con la línea) y `<caso>-base.png` (con la
    línea oculta) del MISMO instante. El registro `capturas.json` trae, por caso,
    en qué píxel cae cada estación de la ventana visible y qué estado dice la
    línea en ella: se comprueba que el color pintado ahí sea el que dice.
  * La goma de la trazada no se adivina: son los píxeles que cambian entre el
    fotograma sin línea de la tanda corregida (`disparos/goma-base.png`) y el MISMO
    sitio y la MISMA pose en la tanda que se captura entera con la corrección apagada
    (`disparos-antes/goma-base.png`). Lo único que cambia entre los dos PNG es el
    material de la goma, así que la diferencia ES la franja. Que las dos tandas caen en
    la misma pose se mide, no se supone: el asfalto de al lado sale idéntico.
    Además, `disparos/goma-original.png` (el material del GLB puesto en caliente en la
    tanda corregida) tiene que medir lo mismo que el "antes" de la otra tanda.

Sale con código distinto de cero si algo no se cumple.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

DIR = Path(__file__).resolve().parent
SHOTS = DIR / "disparos"
SHOTS_ANTES = DIR / "disparos-antes"
REGISTRO = DIR / "capturas.json"
REGISTRO_ANTES = DIR / "capturas-antes.json"

# --- criterios declarados ----------------------------------------------------
COLORES = ["verde", "amarillo", "rojo"]
ESTADO_A_COLOR = {"VERDE": "verde", "AMARILLO": "amarillo", "ROJO": "rojo"}
# Distancia de color: la ponderación habitual (el verde pesa más porque el ojo lo
# distingue mejor). Un píxel "es" de un color si está a menos de esto de él.
PESO = np.array([2.0, 4.0, 3.0])
TOLERANCIA_COLOR = 55.0
ACIERTO_MINIMO = 0.90            # muestras pautadas con el color que dice la línea
# Muestras sólidas visibles que exige cada caso. Son 3 y no más porque el caso `salida`
# (el coche en la línea de meta, con la trazada lejos) deja la línea a 17 px y sólo tres de
# sus estaciones son sólidas; los otros tres casos tienen 16, 11 y 10. Lo que no se relaja es
# el acierto: en cada muestra sólida el píxel tiene que ser del color que la línea dice.
MUESTRAS_MINIMAS = 3
AGUJEROS_MAXIMO = 0.10           # dentro del listón, fracción que no es su color
ANCHO_LINEA_M = 0.46             # ancho declarado del listón (0,46 m desde la fase visual)
ANCHO_HOLGURA = 1.30
# La goma de la trazada se mide sobre los píxeles que cambian entre el MISMO instante con el
# material del GLB y con el corregido: esa diferencia ES la franja, sin depender de que dos
# ejecuciones hayan quedado con la misma cámara. El contraste se mide contra el asfalto de la
# MISMA fila (misma profundidad, misma luz) a 8..40 px de lado, y se descartan los píxeles que
# también cambian entre los dos fotogramas (líneas pintadas, bordillos, ruido del TAA).
GOMA_COMPONENTE_MIN = 300        # px por componente: por debajo es ruido de antialiasing
GOMA_PIXELES_MIN = 4000          # px de franja para creer la medida
GOMA_DOMINANTE_MARGEN = 8.0      # más color propio que su asfalto, sobre 255
GOMA_AZUL_MARGEN = 8.0           # margen por encima del asfalto para azul propio de la goma
GOMA_OSCURA_MIN = 8.0            # cuánto más oscura que el asfalto, en % de luminancia
GOMA_OSCURA_MAX = 32.0
GOMA_ANILLO_MIN = 8              # px: a menos, es el borde mezclado de la franja
GOMA_ANILLO_MAX = 40             # px: a más, se sale de la misma profundidad
GOMA_ANTES_MARGEN = 8.0          # el control de la otra ejecución tiene que dar lo mismo
GOMA_DOMINANTE_MEJORA_MIN = 15.0  # cuánto tiene que bajar la dominante con la corrección
DISTANCIA_REFERENCIA_MIN = 45.0  # los tres colores tienen que distinguirse
# Cuánto tienen que separarse las tres capturas forzadas EN UN PÍXEL para dar por sentado
# que la línea pasa por ahí: donde no llega, las tres forzadas pintan el mismo asfalto y no
# hay color que clasificar (sin esto, el asfalto de al lado del listón se "clasificaba" del
# color de la línea y la anchura medida salía de 1,70 m, el ancho del corte entero).
DISTANCIA_LOCAL_MIN = 30.0
CANAL_MAXIMO = 238.0             # moderación: nada de canales al tope
# Cromaticidad = saturación × valor. Un verde oscuro tiene la saturación de la
# escala 1 y no es un neón (medido: (2,84,12) da 0,32); un verde puro de pantalla
# daría 1,0. Es la medida de "no estridente" que sí distingue las dos cosas.
CROMATICIDAD_MAXIMA = 0.78
DIFERENCIA_GOMA = 12.0           # cambio mínimo por canal para contar un píxel de goma
# Cambio mínimo por canal entre el fotograma con la línea y el mismo instante con la línea
# oculta para dar por DIBUJADO ese píxel. Donde el listón queda tapado por el terreno o
# por el coche el píxel es del fondo, así que no se le puede exigir su color; lo que sí se
# exige es que la línea esté a la vista en una fracción suficiente de la ventana.
DIFERENCIA_LINEA = 30.0
COBERTURA_MINIMA = 0.45

fallos: list[str] = []
log: list[str] = []


def ok(texto: str) -> None:
    log.append("PASS " + texto)


def fail(texto: str) -> None:
    log.append("FAIL " + texto)
    fallos.append(texto)


def check(condicion: bool, texto: str) -> None:
    ok(texto) if condicion else fail(texto)


def leer(ruta: Path) -> np.ndarray:
    return np.asarray(Image.open(ruta).convert("RGB")).astype(np.float64)


def medir(imagen: np.ndarray, punto: dict, radio: int = 1) -> np.ndarray | None:
    """Color medio de un cuadradito alrededor del píxel pautado."""
    if punto.get("detras"):
        return None
    x, y = int(round(float(punto["x"]))), int(round(float(punto["y"])))
    alto, ancho = imagen.shape[0], imagen.shape[1]
    if x < radio or y < radio or x >= ancho - radio or y >= alto - radio:
        return None
    bloque = imagen[y - radio : y + radio + 1, x - radio : x + radio + 1]
    return bloque.reshape(-1, 3).mean(axis=0)


def distancia(color: np.ndarray, referencia: np.ndarray) -> float:
    d = (color - referencia) * PESO
    return float(np.sqrt((d * d).sum()))


def clasificar(color: np.ndarray, referencias: dict[str, np.ndarray],
               tolerancia: float | None = TOLERANCIA_COLOR) -> str:
    """El color más cercano al medido.

    Con `tolerancia` (la de por defecto) un píxel que no se parece a ninguno es "otro". Con
    `tolerancia=None` gana el más cercano aunque esté lejos: es lo que se usa cuando la
    referencia es el color que el motor pinta EN ESE MISMO PÍXEL con la línea forzada a cada
    color —el listón proyecta de 1 a 3 px y el píxel puede ser una mezcla con el asfalto—,
    donde lo que se exige es que la mezcla esté más cerca del color que la línea dice que de
    los otros dos, no que sea el color puro.
    """
    mejor, minimo = "otro", float("inf") if tolerancia is None else tolerancia
    for nombre, referencia in referencias.items():
        d = distancia(color, referencia)
        if d < minimo:
            mejor, minimo = nombre, d
    return mejor


def _referencias_locales(forzados: dict[str, np.ndarray], punto: dict, radio: int) -> dict | None:
    """Los tres colores que el motor pinta en ESE píxel con la línea forzada a cada color.

    Devuelve {} si el caso no trae capturas forzadas (entonces se usan las referencias medias
    del caso) y None si en ese píxel las tres forzadas son el mismo color: por ahí no pasa la
    línea y no hay nada que clasificar.
    """
    if not forzados:
        return {}
    locales: dict[str, np.ndarray] = {}
    for nombre, forzada in forzados.items():
        valor = medir(forzada, punto, radio)
        if valor is not None:
            locales[nombre] = valor
    if len(locales) != len(COLORES):
        return None
    separacion = max(distancia(locales[a], locales[b])
                     for i, a in enumerate(COLORES) for b in COLORES[i + 1 :])
    return locales if separacion >= DISTANCIA_LOCAL_MIN else None


def cromaticidad(color: np.ndarray) -> float:
    """Saturación × valor: cuánto de estridente es un color, oscuro o claro."""
    mayor, menor = float(color.max()), float(color.min())
    if mayor <= 0.0:
        return 0.0
    return (mayor - menor) / 255.0


def _luminancia(color: np.ndarray) -> float:
    """Luminancia de un color medio: como la ve el ojo, no la media de los canales."""
    return float(0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2])


def _en_mascara(imagen: np.ndarray, mascara: np.ndarray, punto: dict) -> bool:
    x, y = int(round(float(punto["x"]))), int(round(float(punto["y"])))
    alto, ancho = mascara.shape
    if x < 0 or y < 0 or x >= ancho or y >= alto:
        return False
    return bool(mascara[y, x])


def main() -> int:
    if not REGISTRO.exists():
        print(f"no existe el registro de capturas: {REGISTRO}")
        return 1
    datos = json.loads(REGISTRO.read_text())
    antes = json.loads(REGISTRO_ANTES.read_text()) if REGISTRO_ANTES.exists() else None
    print(f"LINEA_PX lienzo={datos['lienzo']} casos={len(datos['casos'])} modo={datos.get('modo')} "
          f"goma_escala_de_grises={datos.get('escala_de_grises')}")

    antes_por_id = {c["id"]: c for c in (antes or {}).get("casos", [])}

    # --- 1. los colores de referencia de cada caso ---------------------------
    referencias: dict[str, dict[str, np.ndarray]] = {}
    for caso in datos["casos"]:
        ident = caso["id"]
        refs: dict[str, np.ndarray] = {}
        for color in COLORES:
            entrada = (caso.get("referencias") or {}).get(color)
            if entrada is None:
                continue
            refs[color] = np.array(entrada["rgb"], dtype=float)
        if len(refs) < 3:
            fail(f"el caso {ident} no tiene los tres colores de referencia medidos")
            continue
        referencias[ident] = refs
        print("LINEA_PX referencias caso=%-13s verde=(%3.0f,%3.0f,%3.0f) amarillo=(%3.0f,%3.0f,%3.0f) rojo=(%3.0f,%3.0f,%3.0f)" % (
            ident, *refs["verde"], *refs["amarillo"], *refs["rojo"]))

    if not referencias:
        print("\n".join(log))
        print("LINEA_PX FAIL comprobaciones=%d fallos=%d" % (len(log), len(fallos)))
        return 1

    # --- 2. los tres colores: moderados y distinguibles entre sí -------------
    # Se evalúan en cada caso (la pose cambia el tono que pinta el motor) y se
    # informa el peor de todos.
    peor_canal = 0.0
    peor_cromaticidad = 0.0
    peor_distancia = (1e9, "", "")
    for ident, refs in referencias.items():
        for color, rgb in refs.items():
            peor_canal = max(peor_canal, float(rgb.max()))
            peor_cromaticidad = max(peor_cromaticidad, cromaticidad(rgb))
        for i, a in enumerate(COLORES):
            for b in COLORES[i + 1 :]:
                d = distancia(refs[a], refs[b])
                if d < peor_distancia[0]:
                    peor_distancia = (d, a, b)
    check(peor_canal <= CANAL_MAXIMO,
          f"ninguno de los tres colores llega al tope del canal (peor {peor_canal:.0f} ≤ {CANAL_MAXIMO:.0f})")
    check(peor_cromaticidad <= CROMATICIDAD_MAXIMA,
          f"ninguno de los tres colores es estridente (peor cromaticidad {peor_cromaticidad:.2f} ≤ {CROMATICIDAD_MAXIMA:.2f})")
    check(peor_distancia[0] >= DISTANCIA_REFERENCIA_MIN,
          f"los tres colores se distinguen entre sí (peor par {peor_distancia[1]}/{peor_distancia[2]} "
          f"a distancia {peor_distancia[0]:.0f} ≥ {DISTANCIA_REFERENCIA_MIN:.0f})")

    # --- 3. cada caso: el color pintado donde la línea dice ------------------
    anchos_goma_por_caso: dict[str, float] = {}
    casos_sin_goma: list[str] = []
    # Cuánto puede separarse el centro del listón del centro de la trazada, en metros. El
    # corte transversal se mide sobre la trazada y el listón tiene 0,46 m de ancho, así que
    # 0,11 m es el margen de una muestra lateral de 0,1 m a cada lado.
    CENTRO_TRAZADA_MAX = 0.11
    for caso in datos["casos"]:
        ident = caso["id"]
        refs = referencias.get(ident)
        if refs is None:
            continue
        con = SHOTS / f"{ident}-linea.png"
        sin = SHOTS / f"{ident}-base.png"
        if not con.exists() or not sin.exists():
            fail(f"faltan las capturas del caso {ident}")
            continue
        imagen = leer(con)
        base = leer(sin)
        # Las tres capturas de referencia DEL CASO: la misma pose, la misma velocidad y el
        # MISMO píxel con la línea forzada a un solo color. Clasificar contra el color que
        # ese píxel tiene forzado —y no contra la media del caso— es lo que hace la
        # comprobación independiente del ancho con que proyecta el listón en cada estación.
        forzados: dict[str, np.ndarray] = {}
        for color in COLORES:
            ruta_forzada = SHOTS / f"{ident}-forzado-{color}.png"
            if ruta_forzada.exists():
                forzados[color] = leer(ruta_forzada)
        aciertos = mirados = 0
        tapadas = 0
        detalle: list[str] = []
        for muestra in caso["muestras"]:
            if muestra["ocluido"] or muestra.get("mixta"):
                continue
            color = medir(imagen, muestra["punto"])
            fondo = medir(base, muestra["punto"])
            if color is None or fondo is None:
                continue
            # Fuera del listón (tapado por el terreno, por el coche o fuera del lienzo) no
            # hay color que exigir: lo que se mide es que donde la línea SE VE, el color
            # sea el que la línea dice.
            if np.abs(color - fondo).max() <= DIFERENCIA_LINEA:
                tapadas += 1
                continue
            esperado = ESTADO_A_COLOR[muestra["estado"]]
            locales = _referencias_locales(forzados, muestra["punto"], 1)
            if locales is None:
                # En este píxel las tres forzadas pintan lo mismo: la línea no llega aquí en
                # ninguna de las tres, así que no hay color que exigirle al fotograma.
                tapadas += 1
                continue
            obtenido = clasificar(color, locales, None) if locales else clasificar(color, refs)
            mirados += 1
            if obtenido == esperado:
                aciertos += 1
            elif len(detalle) < 4:
                detalle.append("ds=%.0f esperado=%s obtenido=%s rgb=(%d,%d,%d)" % (
                    muestra["ds"], esperado, obtenido, *color))
        if mirados < MUESTRAS_MINIMAS:
            fail(f"el caso {ident} no tiene muestras sólidas visibles (sólo {mirados})")
            continue
        cobertura = mirados / (mirados + tapadas)
        print("LINEA_PX caso=%-13s muestras=%2d aciertos=%2d (%3.0f %%) tapadas=%2d cobertura=%3.0f %% visibles=%2d %s" % (
            ident, mirados, aciertos, aciertos / mirados * 100.0, tapadas, cobertura * 100.0, caso["visibles"],
            str(caso["visibles_por_estado"])))
        check(cobertura >= COBERTURA_MINIMA,
              f"{ident}: la línea se ve a lo largo de la ventana ({cobertura * 100:.0f} % de las muestras "
              f"cambian el píxel, mínimo {COBERTURA_MINIMA * 100:.0f} %)")
        check(aciertos / mirados >= ACIERTO_MINIMO,
              f"{ident}: el color pintado donde la línea dice es el que dice ({aciertos}/{mirados} muestras; {'; '.join(detalle)})")

        # --- 4. cortes transversales: agujeros, anchura y goma ----------------
        # La franja de goma de ESTA pose: los píxeles que cambian entre el fotograma con la
        # línea oculta y el mismo instante con el material del GLB. Si no está el par del
        # mismo instante se cae al par de la otra ejecución (el control), que es la misma
        # pose medida: allí el asfalto sale idéntico.
        mascara_goma = None
        previo_mismo = SHOTS / f"{ident}-base-original.png"
        previo_control = SHOTS_ANTES / f"{ident}-base.png"
        for candidato in (previo_control, previo_mismo):
            if not candidato.exists():
                continue
            a = leer(candidato)
            if a.shape != base.shape:
                fail(f"{ident}: las capturas antes/después del caso no tienen el mismo tamaño")
                continue
            # Una apertura quita el grano del antialiasing temporal: lo que queda son los
            # tramos de franja, no píxeles sueltos.
            mascara_goma = ndi.binary_opening(np.abs(a - base).max(axis=2) > DIFERENCIA_GOMA,
                                              np.ones((3, 3)))
            break
        anchos: list[float] = []
        anchos_goma: list[float] = []
        centros: list[float] = []
        separaciones: list[float] = []
        agujeros: list[float] = []
        for muestra in caso["muestras"]:
            corte = muestra.get("cruce")
            if corte is None or muestra["ocluido"] or muestra.get("mixta"):
                continue
            esperado = ESTADO_A_COLOR[muestra["estado"]]
            clasificados: dict[float, str] = {}
            del_goma: list[float] = []
            validos = 0
            for punto in corte:
                color = medir(imagen, punto["punto"], 0)
                if color is None:
                    continue
                validos += 1
                lado = round(float(punto["lado"]), 1)
                locales = _referencias_locales(forzados, punto["punto"], 0)
                if locales is None:
                    # Fuera del listón: ahí no hay color de la línea que exigir.
                    clasificados[lado] = "otro"
                elif locales:
                    clasificados[lado] = clasificar(color, locales, None)
                else:
                    clasificados[lado] = clasificar(color, refs)
                if mascara_goma is not None and _en_mascara(base, mascara_goma, punto["punto"]):
                    del_goma.append(lado)
            if validos < 15:
                continue
            # Anchura: el recorrido contiguo del color pautado alrededor del centro, y
            # el centro del listón mirado aparte para el agujero (el borde puede caer ya
            # en el asfalto por el propio muestreo de un píxel).
            lados_liston = [0.0]
            for sentido in (0.1, -0.1):
                lado = 0.0
                while abs(lado + sentido) <= 0.85 + 1e-6 and clasificados.get(round(lado + sentido, 1)) == esperado:
                    lado = round(lado + sentido, 1)
                    lados_liston.append(lado)
            anchos.append((max(lados_liston) - min(lados_liston)) * 1.0 + 0.1)
            anchos_goma.append((max(del_goma) - min(del_goma)) * 1.0 + 0.1 if del_goma else 0.0)
            # Dónde queda el listón respecto a la TRAZADA que sigue el juego: el corte está
            # centrado en ella (lado 0,0), así que el centro del listón tiene que caer ahí.
            # Es la comprobación de que la línea va SOBRE la trazada.
            centros.append((max(lados_liston) + min(lados_liston)) / 2.0)
            # Y la separación con la franja de goma del mod, que es un decal pintado a mano
            # que va por donde va (medido: hasta 0,6 m a un lado en plena recta). Se informa
            # —es la franja que se ha neutralizado— pero no se le exige coincidir con la
            # trazada del juego: el encargo pide la línea sobre la TRAZADA, no sobre el decal.
            if del_goma:
                separaciones.append(centros[-1] - (max(del_goma) + min(del_goma)) / 2.0)
            centro = [clasificados.get(l) for l in (-0.1, 0.0, 0.1)]
            agujeros.append(sum(1 for c in centro if c != esperado) / 3.0)
        if anchos:
            ancho = float(np.median(anchos))
            ancho_goma = float(np.median(anchos_goma))
            hueco = float(np.median(agujeros)) if agujeros else 0.0
            desvio = float(np.median(centros)) if centros else 0.0
            separacion = float(np.median(separaciones)) if separaciones else float("nan")
            print("LINEA_PX caso=%-13s ancho_liston=%.2f m centro_liston=%+.2f m (de la trazada) "
                  "ancho_goma=%.2f m separacion_goma=%s agujeros=%.0f %% (cortes=%d)" % (
                      ident, ancho, desvio, ancho_goma,
                      "n/d" if np.isnan(separacion) else "%+.2f m" % separacion,
                      hueco * 100.0, len(anchos)))
            check(abs(desvio) <= CENTRO_TRAZADA_MAX,
                  f"{ident}: el listón va centrado sobre la trazada que sigue el juego "
                  f"(centro medido {desvio:+.2f} m de ella, |desvío| ≤ {CENTRO_TRAZADA_MAX:.2f} m)")
            check(hueco <= AGUJEROS_MAXIMO,
                  f"{ident}: dentro del listón no asoma el asfalto (agujeros {hueco * 100:.0f} % ≤ {AGUJEROS_MAXIMO * 100:.0f} %)")
            check(ancho <= ANCHO_LINEA_M * ANCHO_HOLGURA,
                  f"{ident}: el listón de color no pasa del ancho declarado (medido {ancho:.2f} m ≤ {ANCHO_LINEA_M * ANCHO_HOLGURA:.2f} m)")
            if ancho_goma > 0.0:
                anchos_goma_por_caso[ident] = ancho_goma
            else:
                # En algunas poses (curva cerrada, el decal del mod por dentro) los cortes
                # caen fuera de la franja de goma: no es un fallo de la línea, así que se
                # informa y se exige, al final, que OTROS casos sí la vean.
                casos_sin_goma.append(ident)

    # --- 5. la goma de la trazada: gris de asfalto, sin azul y algo más oscura --
    #
    # Los tres fotogramas que se comparan son:
    #   ANTES   `disparos-antes/goma-base.png`: la MISMA pose en la tanda que se captura
    #           entera con la corrección apagada (el material de goma que trae el GLB).
    #   DESPUÉS `disparos/goma-base.png`      : esa misma pose con el material corregido.
    #   CALIENTE `disparos/goma-original.png` : el material del GLB puesto en caliente en la
    #           tanda corregida. Comprueba que el "antes" no depende de la ejecución.
    # Que las dos tandas caen en la misma pose no se supone: se ve en el asfalto de al lado,
    # que sale idéntico (los píxeles del anillo cambian ≤ 6 entre las dos y el anillo existe).
    # La franja son los píxeles que cambian entre ANTES y DESPUÉS —lo único que cambia
    # entre esos dos fotogramas es el material de la goma—, y el asfalto con el que se
    # compara es el de la MISMA fila a 8..40 px de lado, que es la misma profundidad y la
    # misma luz. Así el número no depende del encuadre ni de la exposición de la pose.
    despues = SHOTS / "goma-base.png"
    original = SHOTS_ANTES / "goma-base.png"
    control = SHOTS / "goma-original.png"
    if not despues.exists() or not original.exists():
        fail("faltan los fotogramas de la goma (el corregido y el de la tanda con la corrección apagada)")
    else:
        b = leer(despues)
        a = leer(original)
        if a.shape != b.shape:
            fail("los dos fotogramas de la goma no tienen el mismo tamaño")
        else:
            dif = np.abs(a - b).max(axis=2)
            cruda = dif > DIFERENCIA_GOMA
            limpia = ndi.binary_opening(cruda, np.ones((3, 3)))
            etiquetas, cuantas = ndi.label(limpia)
            tamanos = ndi.sum(limpia, etiquetas, range(1, cuantas + 1)) if cuantas else np.zeros(0)
            grandes = np.nonzero(tamanos >= GOMA_COMPONENTE_MIN)[0] + 1 if tamanos.size else np.zeros(0, int)
            mascara = np.isin(etiquetas, grandes)
            print("LINEA_PX goma mascara=%d px en %d tramos (crudos %d px, el mayor %d px): la diferencia entre "
                  "las dos tandas, misma pose y mismo sitio" % (
                      int(mascara.sum()), int(len(grandes)), int(cruda.sum()),
                      int(tamanos.max()) if tamanos.size else 0))
            if mascara.sum() < GOMA_PIXELES_MIN:
                fail(f"la corrección de la goma no cambia píxeles suficientes de la calzada "
                     f"({int(mascara.sum())} < {GOMA_PIXELES_MIN})")
            else:
                anillo = (ndi.binary_dilation(mascara, np.ones((1, 2 * GOMA_ANILLO_MAX + 1)))
                          & ~ndi.binary_dilation(mascara, np.ones((1, 2 * GOMA_ANILLO_MIN + 1)))
                          & (dif <= 6.0))
                if int(anillo.sum()) < 500:
                    fail("no hay asfalto medible al lado de la franja de goma")
                else:
                    medidas: dict[str, dict[str, float]] = {}
                    parejas = [("ANTES  ", a), ("DESPUÉS", b)]
                    if control.exists():
                        parejas.append(("CALIENTE", leer(control)))
                    for etiqueta, imagen in parejas:
                        if imagen.shape != a.shape:
                            continue
                        colores = imagen[mascara]
                        vecinos = imagen[anillo]
                        dominante = float(np.median(colores.max(axis=1) - colores.min(axis=1)))
                        dominante_asfalto = float(np.median(vecinos.max(axis=1) - vecinos.min(axis=1)))
                        propia, ajena = _luminancia(colores.mean(axis=0)), _luminancia(vecinos.mean(axis=0))
                        medidas[etiqueta] = {
                            "dominante": dominante,
                            "dominante_asfalto": dominante_asfalto,
                            "azul": float(colores[:, 2].mean() - colores[:, 0].mean()),
                            "azul_asfalto": float(vecinos[:, 2].mean() - vecinos[:, 0].mean()),
                            "contraste": (ajena - propia) / ajena * 100.0 if ajena > 0.0 else 0.0,
                        }
                        print("LINEA_PX goma %s px=%6d rgb=(%3.0f,%3.0f,%3.0f) dominante=%.1f/255 azul-rojo=%+.1f | "
                              "asfalto rgb=(%3.0f,%3.0f,%3.0f) dominante=%.1f/255 azul-rojo=%+.1f | contraste=%+.1f %%" % (
                                  etiqueta, int(mascara.sum()), *colores.mean(axis=0), dominante,
                                  medidas[etiqueta]["azul"], *vecinos.mean(axis=0), dominante_asfalto,
                                  medidas[etiqueta]["azul_asfalto"], medidas[etiqueta]["contraste"]))
                    antes, despues_m = medidas.get("ANTES  "), medidas.get("DESPUÉS")
                    if antes is None or despues_m is None:
                        fail("no se pudieron medir los dos materiales de la goma")
                    else:
                        check(despues_m["dominante"] <= antes["dominante"] - GOMA_DOMINANTE_MEJORA_MIN,
                              f"la corrección quita dominante de color a la franja (dominante {despues_m['dominante']:.1f} "
                              f"≤ {antes['dominante']:.1f} − {GOMA_DOMINANTE_MEJORA_MIN:.0f})")
                        check(despues_m["dominante"] <= despues_m["dominante_asfalto"] + GOMA_DOMINANTE_MARGEN,
                              f"la franja no tiene más color propio que el asfalto de su misma fila "
                              f"({despues_m['dominante']:.1f} ≤ {despues_m['dominante_asfalto']:.1f} + {GOMA_DOMINANTE_MARGEN:.0f})")
                        check(despues_m["azul"] <= despues_m["azul_asfalto"] + GOMA_AZUL_MARGEN,
                              f"la franja no es más azul que el asfalto que la rodea "
                              f"(azul−rojo {despues_m['azul']:+.1f} ≤ {despues_m['azul_asfalto']:+.1f} + {GOMA_AZUL_MARGEN:.0f})")
                        check(GOMA_OSCURA_MIN <= despues_m["contraste"] <= GOMA_OSCURA_MAX,
                              f"la franja queda algo más oscura que el asfalto, sin ser un agujero "
                              f"({despues_m['contraste']:.1f} % dentro de {GOMA_OSCURA_MIN:.0f}-{GOMA_OSCURA_MAX:.0f} %)")
                        check(antes["contraste"] < 0.0,
                              f"el material del GLB brillaba más que el asfalto (el defecto: {antes['contraste']:+.1f} %; "
                              f"la corrección lo deja {despues_m['contraste']:+.1f} %)")
                        if "CALIENTE" in medidas:
                            desvio = abs(medidas["CALIENTE"]["dominante"] - antes["dominante"])
                            check(desvio <= GOMA_ANTES_MARGEN,
                                  f"el 'antes' no depende de la ejecución: el material del GLB puesto en caliente mide lo "
                                  f"mismo que la tanda con la corrección apagada (dominante "
                                  f"{medidas['CALIENTE']['dominante']:.1f} vs {antes['dominante']:.1f}, "
                                  f"desvío {desvio:.1f} ≤ {GOMA_ANTES_MARGEN:.0f})")

    # --- 6. la franja de goma en los cortes de cada caso ---------------------
    if anchos_goma_por_caso:
        ok("la goma de la trazada se ve en los cortes de " + ", ".join(sorted(anchos_goma_por_caso)) +
           " (anchuras medidas " + ", ".join("%.2f m" % v for _, v in sorted(anchos_goma_por_caso.items())) + ")")
    else:
        fail("ningún corte transversal ve la goma de la trazada: el listón no se puede situar sobre ella"
             + (" (casos sin goma en los cortes: %s)" % ", ".join(casos_sin_goma) if casos_sin_goma else ""))

    for linea in log:
        print("LINEA_PX", linea)
    print("LINEA_PX %s comprobaciones=%d fallos=%d" % ("PASS" if not fallos else "FAIL", len(log), len(fallos)))
    return 0 if not fallos else 1


if __name__ == "__main__":
    sys.exit(main())
