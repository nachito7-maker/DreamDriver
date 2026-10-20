# Fase — Reparación de las ruedas TRASERAS del Red Bull

**Fecha:** 15 de octubre de 2026 · **Ámbito:** la GOMA de las dos ruedas traseras del
activo que usa el juego (`assets/RedBull-Drive.glb`) · **No toca:** las ruedas
delanteras, la llanta de las traseras, el chasis, la cámara, la física, la suspensión,
la posición del coche, el circuito, el HUD ni los controles.

**Resumen.** Las ruedas traseras se veían «rotas» y **no era la forma: era que a la
goma le faltaba superficie**. El activo entregado trae la goma de cada trasera
partida en **cuatro gajos de 90° que no se cosen entre sí** (más cuatro restos de 16
vértices en las juntas: ocho piezas por rueda), y por las juntas se ve el **barril
metálico de la llanta**. Medido con rayos que entran de fuera hacia el eje: en las
traseras **el 61,9 % de las direcciones dan en la llanta y el 3,6 % atraviesan la
rueda**; en las delanteras, que son la referencia, **el 100 % dan en la goma**. Eso es
exactamente el «tambor plateado» de la captura del juego.

La causa está documentada en el proyecto anterior y reproducida aquí: sus traseras se
construyeron con «relleno por simetría de revolución» (se conserva el sector de 90°
mejor cubierto y se rota tres veces más). Esta fase sustituye **sólo la goma de las
dos traseras** por una **funda de revolución cerrada**, generada con las medidas del
propio activo y con la misma construcción que la goma delantera, y **parchea el GLB a
nivel binario**: todo lo que no son esas dos gomas queda byte a byte igual.

| Medida (auditoría de malla + prueba nueva) | delantera izq. | delantera der. | trasera izq. **antes** | trasera der. **antes** | trasera izq. **después** | trasera der. **después** |
| --- | --- | --- | --- | --- | --- | --- |
| Rayos que ven **goma** en la banda | **2880/2880 (100 %)** | 100 % | 636/2880 (**22,1 %**) | 22,1 % | **2880/2880 (100 %)** | **100 %** |
| Rayos que ven la **llanta** | 0 | 0 | 1784 (**61,9 %**) | 61,9 % | **0** | **0** |
| Rayos que **atraviesan** la rueda | 0 | 0 | 104 (**3,6 %**) | 3,6 % | **0** | **0** |
| Piezas de la goma (fusión a 0,1 mm) | 2 | 4 | **8** | 8 | **1** | **1** |
| Caras de la goma | 4039 | 4084 | 3150 | 3150 | 2048 | 2048 |
| Silueta del neumático (dispersión por sector) | 0,01 mm | 0,08 mm | 0,00 mm | 0,00 mm | 0,00 mm | 0,00 mm |
| Diámetros radiales A × B | 748,07 × 748,08 | 750,55 × 750,46 | 745,72 × 745,72 | 745,72 × 745,72 | 745,78 × 745,78 | 745,78 × 745,78 |
| Problemas del auditor | 0 | 0 | **1** | **1** | **0** | **0** |

---

## 1. El defecto, medido (y por qué las auditorías anteriores no lo veían)

Las cuatro sondas y auditorías que ya existían **daban `passed=true` con las traseras
rotas**, y no por descuido: miran la caja envolvente, la silueta, los diámetros, la
corona, el reparto de materiales y la cobertura angular, y **ninguna de esas medidas
puede ver que falta superficie**:

| Medida existente | Antes | Después | ¿Ve el defecto? |
| --- | --- | --- | --- |
| Caja envolvente (radio, anchura) y pivote | 372,89 mm · 457,48 mm · (0,0,0) | igual | no: la caja no cambia |
| Silueta del neumático por sector (72 sectores) | **0,00 mm** | **0,00 mm** | no: los gajos llegan al radio correcto |
| Diámetros radiales | 745,72 = 745,72 | 745,78 = 745,78 | no: son iguales |
| Corona (radio por décima de anchura) | 0,00 mm | 0,00 mm | no |
| Reparto goma/llanta contra el barril | 0,0 mm | 0,0 mm | no |
| **Cobertura angular exacta** de la banda (unión de los tramos que cubre cada triángulo) | **100,0000 %** | **100,0000 %** | **no**: los restos de las juntas cubren el ángulo |
| **Visibilidad** — la primera superficie que ve un rayo que entra de fuera | **22,1 % goma** | **100 % goma** | **sí** |

La cobertura angular se midió expresamente para este informe y se descartó como
criterio: sale 100 % en las dos situaciones. Es el mismo punto ciego que dejó pasar el
defecto en el proyecto anterior, cuyo criterio era «el sector cuenta como cubierto si
su radio máximo llega al 93 % del radio del recorte» (72/72 sectores: aprobado con las
muescas dentro).

### 1.1 Causa raíz (documentada en el proyecto anterior y reproducida)

`VehiclePrototypes/tools/produce_fleet.py` §11b, y la fila del Red Bull en su tabla de
decisiones: *«delanteras intactas | traseras: `bl` por revolución, `br` donante de
`bl`»* — **solo las traseras**. El «relleno por simetría de revolución» conserva el
sector de 90° mejor cubierto de una rueda recortada y lo rota 90°, 180° y 270°: la
rueda queda entera *de radio*, pero los cuatro gajos no llegan a tocarse.

Medido en el activo entregado, antes de esta reparación:

- la goma de cada trasera = **4 gajos de 485 vértices + 4 restos de 16 vértices**;
  cada gajo abarca el ancho y el radio completos, así que las juntas son
  *atravesables*;
- las juntas dejan huecos reales: de 2880 rayos radiales, 1784 (61,9 %) dan en la
  **llanta** y 104 (3,6 %) **no dan en nada** (se ve el fondo a través de la rueda);
- la llanta arrastra el mismo artefacto (4 piezas que no cierran): por el eje,
  **el 2,2 % de las direcciones atraviesan el disco** (16 de 720 a r = 224,7 mm),
  frente al 0,3 % de la delantera (5 de 360 en todo el disco).

### 1.2 Diferencias con las delanteras (que funcionan)

| | delantera izq. | trasera izq. (antes) |
| --- | --- | --- |
| Piezas de la goma | 2 (una de ellas la funda completa) | **8 (cuatro gajos + cuatro restos)** |
| Construcción de la goma | funda cerrada: banda + superficie interior + cantos planos | cuatro gajos abiertos, **sin** superficie interior en el centro |
| Piezas de la llanta | 2 | 4 |
| Radio exterior | 374,05 mm | 372,89 mm |
| Anchura | 315,19 mm | 457,48 mm |
| Espesor radial de la goma (banda − barril) | 374,05 − 201,1 = **172,9 mm** | 372,89 − 231,4 = **141,5 mm** |
| Barril de la llanta (talón medido) | 0,537 R | 0,621 R |
| Disco visible por el agujero de la goma | hasta 0,54 R | hasta 0,62 R |
| Rayos que ven goma desde fuera | **100 %** | **22,1 %** |

Las dos ruedas traseras son idénticas entre sí (mismos radios, anchuras 457,48 y
457,68 mm) y su goma es la que faltaba: la delantera es una funda cerrada; la trasera
no tenía ninguna.

---

## 2. La reparación, localizada

**Qué se ha sustituido:** únicamente la **goma** (caras del material `mat_fleet_tire`)
de `wheel_rl` y `wheel_rr`. **Qué no se ha tocado:** la llanta (sus 4 084 caras quedan
igual), las ruedas delanteras (idénticas byte a byte), el chasis, los nodos (mismas
traslaciones), los materiales, las texturas, las UVs, el pivote y el plano de contacto.

**La funda nueva** se genera con las medidas del propio activo y con la construcción de
la goma delantera (medida sobre ella, no supuesta):

| Parámetro | Valor | De dónde sale |
| --- | --- | --- |
| Radio exterior | **372,89 mm** | el radio máximo que ya tenía cada rueda (`wheel_rl` y `wheel_rr`) |
| Radio interior (agujero) | **232,42 mm** | el **barril medido** de su llanta (231,42 mm, mismo algoritmo que la auditoría) **+ 1 mm** de holgura, para no dejar la goma coplanaria con el barril (la delantera guarda 0,9 mm) |
| Anchura | **457,48 / 457,68 mm** | la de la propia rueda (media anchura 228,74 / 228,84 mm) |
| Cantos | planos | la goma delantera los tiene planos (su sección es un rectángulo: banda de 374 mm constante y superficie interior a 202 mm) |
| Resolución angular | 256 gajos (1,41°) | flecha de 0,11 mm a 373 mm de radio: por debajo de cualquier zoom |
| Normales | hacia el material (banda hacia el eje, agujero hacia fuera, cantos hacia el centro) | es la convención **medida** en la goma delantera: banda n·radial = −0,995; interior +0,83; cantos hacia el centro |
| Enrollado | el mismo que produce esa normal geométrica | la auditoría mide 0 % del área con la normal almacenada al revés, como en la delantera |
| Material | `mat_fleet_tire` (el que ya existía) | es de color plano y de **doble cara**, sin textura: no consume UVs (el activo no tiene TEXCOORD_0 en la goma; la auditoría lo confirma) |

Autocomprobación de la funda generada: **2048 vértices, 2048 caras, 1 pieza conexa,
radio 372,890/232,420 mm, anchura 457,480 mm, 0 caras con la normal al revés**
(`.tools/wheels/reparacion-traseras.json`).

**Cómo se aplica: parche binario del GLB, sin pasar por Blender.** Se añaden los
búferes nuevos al final del BIN y se reapunta la primitiva de goma de las dos mallas
traseras; **nada más**. Comprobado en el propio reparador y repetido aquí:

| Parte del activo | Resultado |
| --- | --- |
| BIN original como prefijo del nuevo | **exacto** (todos los bytes anteriores, iguales) |
| Nodos (`Body`, `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr`) | **idénticos** (mismas traslaciones, sin rotación ni escala) |
| Materiales, texturas, imágenes, samplers | **idénticos** |
| Mallas `mesh_body_l0`, `mesh_wheel_fl_l0.001`, `mesh_wheel_fr_l0.001` | **idénticas** |
| Mallas `mesh_wheel_bl_l0.001`, `mesh_wheel_br_l0.002` | cambia **sólo la primitiva 0** (la goma) |
| Tamaño del activo | 26 595 516 → **26 743 940 bytes** (+148 KB; la goma vieja queda como datos muertos, ver limitaciones) |

Copia de recuperación del estado de partida, con huellas:
[`backup-20261015/`](.tools/recovery/fase-traseras/backup-20261015/MANIFEST.md).

**Reproducible:**

```bash
python3 .tools/wheels/reparar_traseras.py assets/RedBull-Drive.glb .tools/wheels/traseras-reparadas.glb
python3 .tools/recovery/audit_wheels_mesh.py            # deja de tener problemas
python3 .tools/wheels/ver_la_goma.py                    # la prueba de visibilidad
python3 .tools/wheels/render_piezas.py --rueda wheel_rl # render de la geometría
```

---

## 3. La prueba que faltaba (y que ahora es obligatoria)

El auditor de malla (`.tools/recovery/audit_wheels_mesh.py`) incorpora una medida
nueva, **VISIBILIDAD**: para cada rueda lanza **2880 rayos** (4 planos axiales a
−0,75, −0,25, +0,25 y +0,75 de la media anchura × 720 direcciones) desde fuera hacia el
eje, toma el **primer** triángulo que golpea y exige que sea **goma en la banda**
(radio ≥ 0,98 R). Cualquier rayo que vea la llanta, goma por dentro o nada es un
problema, y el auditor sale con código distinto de cero.

- **Estado de partida:** `wheel_rl` y `wheel_rr` — 636/2880 en la banda (22,08 %),
  356 goma por dentro, 1784 llanta, 104 nada → **2 problemas, salida 1**.
- **Estado entregado:** las cuatro ruedas — **2880/2880 (100 %)** → **0 problemas,
  salida 0**.
- La misma prueba está disponible suelta en `.tools/wheels/ver_la_goma.py`
  (`python3 .tools/wheels/ver_la_goma.py` → «2 de 4 ruedas con la goma incompleta»
  antes, «OK» después).

---

## 4. Verificación

### 4.1 El activo entregado (`.tools/recovery/audit_wheels_mesh.py`)

| Rueda | R mm | ancho | diám.A | diám.B | silueta | corona | área↻ | talón | piezas | visibilidad |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `wheel_fl` | 374,05 | 315,19 | 748,07 | 748,08 | 0,01 | 0,00 | 0,0 % | 0,54 R | 2 | 2880/2880 |
| `wheel_fr` | 375,34 | 315,68 | 750,55 | 750,46 | 0,08 | 0,02 | 0,0 % | 0,54 R | 2 | 2880/2880 |
| `wheel_rl` | 372,89 | 457,48 | 745,78 | 745,78 | 0,00 | 0,00 | 0,0 % | 0,63 R | 5 | **2880/2880** |
| `wheel_rr` | 372,89 | 457,68 | 745,78 | 745,78 | 0,00 | 0,00 | 0,0 % | 0,63 R | 5 | **2880/2880** |

`piezas = 5` en las traseras es lo esperado: **1 funda de goma + las 4 piezas de su
llanta** (que no se tocan entre sí desde el origen; ver limitaciones).

### 4.2 El coche en ejecución (`scripts/car_wheel_probe.gd`, `passed=true errores=0`)

Antes y después, con el activo de cada momento y la misma sonda:

| Medida | antes | después |
| --- | --- | --- |
| Pivote respecto al centro de la malla (las cuatro) | 0,0000 m | 0,0000 m |
| Órbita al girar la rueda (las cuatro) | 0,0000 m | 0,0000 m |
| Eje de giro dominante | X lateral (correcto) | X lateral (correcto) |
| Radio trasero | 372,858 mm | 372,888 mm (**+0,03 mm**) |
| Anchura trasera | 457,478 / 457,684 mm | 457,478 / 457,684 mm |
| Aire bajo la rueda, parado (las cuatro) | −3,7 · −3,7 · −5,4 · −5,4 mm | −3,7 · −3,7 · −5,4 · −5,4 mm |
| Contactos / pose del modelo | 4 / 0,066° | 4 / 0,066° |

### 4.3 El coche en la cámara exterior (`scripts/car_delivery_probe.gd`)

Coche **parado sobre el asfalto**, **en recta a 207 km/h** y **en curva a 111 km/h**,
con ocho puntos de vista en cada situación (cámara del juego, trasera, trasera baja,
tres cuartos, lateral, frontal, rueda trasera y rueda delantera). Capturas completas:
[`capturas-antes/`](.tools/recovery/fase-traseras/capturas-antes) y
[`capturas-despues/`](.tools/recovery/fase-traseras/capturas-despues).

Las capturas **parado** están alineadas píxel a píxel (misma pose, misma cámara), así
que se pueden medir; las de recta y curva no lo están (el coche avanza a distinto
fotograma en cada pasada), así que su comparación es cualitativa:

| Captura parada | Píxeles que cambian | De ellos se oscurecen | Luminancia en esos píxeles | Píxeles de metal claro (>150) |
| --- | --- | --- | --- | --- |
| primer plano de la rueda trasera | 8989 (1,0 % del lienzo) | **97,0 %** | **100,0 → 53,2** | **1394 → 59** |
| trasera centrada | 6440 | 74,3 % | 146,0 → 97,3 | — |
| tres cuartos | 6371 | 51,9 % | 98,4 → 93,2 | — |

Es decir: en la propia captura del juego, el cambio donde antes había llanta vista a
través de la goma es **oscurecimiento** (la goma tapa el metal), y no al revés.

### 4.4 Regresión completa y dispositivo

`./verify.sh` con `SERIAL=emulator-5556` sobre este mismo árbol: ver el registro
[`logs/verify-fase-traseras.log`](.tools/recovery/fase-traseras/logs/verify-fase-traseras.log)
y la tabla `.tools/recovery/integral/checks.tsv` (resultado y APK en §6).

### 4.5 Lo que la batería encontró en su propio instrumento (y no en las ruedas)

La primera corrida de la batería con las ruedas nuevas —**37 comprobaciones `ok` y 1
fallo**— falló `camara_pixeles`, la comprobación que mide en el teléfono si el coche
crece en pantalla al acelerar. Los dos errores venían de la **misma captura**, y
ninguno era del coche ni de las ruedas:

1. «de 152 a 193 km/h el coche no crece (191 → 187 px)»,
2. «`disp-009.png`: la silueta toca el borde».

La causa se midió antes de tocar nada. En `disp-009` (192,7 km/h) la mancha que la
herramienta eligió es una **banda de asfalto en sombra que cruza la pista**: 1 067 px de
ancho (los 1 067 de la ventana de búsqueda, de lado a lado), 187 px de alto, pegada al
borde inferior y con **58 016 píxeles de semilla** de azul oscuro —la sombra tira a azul
y el asfalto oscuro cumple `b − r ≥ 22`, `b − g ≥ 10`, luminancia < 120— frente a los
**12 885 del coche**. El clasificador elige la mancha con más librea, y en esa captura el
asfalto en sombra tenía más azul oscuro que el propio coche. **El coche estaba medido en
la misma captura, en segunda posición, con un ancho de 296 px y 219 px de alto**, que es
exactamente lo que le corresponde entre los 191 px de 152 km/h y los 244 px de
229,5 km/h: la captura no estaba mal, estaba mal elegida la mancha.

La corrección está en el instrumento (`.tools/recovery/camera_pixels.py`) y **no toca el
juego ni relaja ningún criterio**: se descartan los candidatos que **atraviesan la
ventana de búsqueda**, es decir que tocan **dos o más** de sus cuatro bordes. La banda
tocaba **tres** (abajo, izquierda y derecha). El coche no toca **ninguno** en las 12
capturas del anfitrión ni en 15 de las 16 del teléfono; en la única en que toca uno —a
150 km/h en el anfitrión, donde la mancha del coche se pega al borde derecho— sigue
midiéndose bien, y de hecho ése es el caso que descarta la regla ingenua de «no tocar
ningún borde» (con ella el coche se medía **46 px** en vez de 241). Un objeto puede rozar
un borde; lo que no puede es estar cortado por dos a la vez.

Comprobado con lo que la herramienta ya traía, sin añadir nada:

| Prueba | Antes | Después |
| --- | --- | --- |
| `valida` (clasificador contra la resta real de fotogramas, 12 casos del anfitrión) | 3,4 % de peor desvío | **3,4 %, la misma cifra caso por caso** |
| `medida` (la comprobación `audit_camara` de la batería) | `passed=True`, 0 errores | `passed=True`, 0 errores |
| `dispositivo` (16 capturas del teléfono) | **fallo**, 2 errores, factor 1,48 | **`passed=True`, 0 errores, factor 1,74** |
| `disp-009` | 187 px de alto, 1 067 de ancho, margen 6 | **219 px, 296 de ancho, margen 206** |
| Serie de aceleración (`disp-001/005/006/007/009`) | 126 · 132 · 153 · 191 · **187** | 126 · 132 · 153 · 191 · **219** |
| Frenada (`disp-012/013/014/015/016`) | 243 · 232 · 163 · 134 · 128 | **idéntica** |

De las 16 capturas del teléfono **sólo cambia la elección en `disp-009`**; las otras 15
se miden igual que antes del arreglo. La evidencia queda archivada en
[`evidencia-camara/`](.tools/recovery/fase-traseras/evidencia-camara) —el `checks.tsv` que
falla, el informe de la captura, los dos lados del `valida` y del `dispositivo`, y la
copia del instrumento corregido—, y la captura con las dos manchas marcadas (la banda,
en rojo, y el coche, en verde) en
[`diag-disp009.html`](.tools/recovery/fase-traseras/diag/diag-disp009.html). El defecto
está contado desde el otro lado en
[`INFORME-FASE-CAMARA.md` §9.4](../fase-camara/INFORME-FASE-CAMARA.md).

---

## 5. Capturas comparativas

| Qué | Dónde |
| --- | --- |
| Cámara del juego, parado / recta / curva, antes y después | [`comparativa-camara-juego.html`](.tools/recovery/fase-traseras/comparativa-camara-juego.html) |
| Rueda trasera **izquierda**, ampliada (recorte centrado en los píxeles que cambian) | [`comparativa-ampliada.html`](.tools/recovery/fase-traseras/comparativa-ampliada.html) |
| Geometría desnuda (rasterizado propio, color por material), trasera izquierda antes/después y delantera como referencia | [`../../wheels/render/comparativa-traseras.html`](.tools/wheels/render/comparativa-traseras.html) |
| Geometría desnuda, trasera **derecha** antes/después y delantera derecha | [`../../wheels/render/comparativa-rr.html`](.tools/wheels/render/comparativa-rr.html) |
| 24 capturas por situación y punto de vista (8 vistas × parado, recta y curva) | `capturas-antes/` y `capturas-despues/` |
| Cámara del juego, planta, trasera baja y primer plano de la rueda trasera, antes y después | [`comparativa-vistas-sonda.html`](.tools/recovery/fase-traseras/comparativa-vistas-sonda.html) |
| Fotografías de la sonda de ruedas en marcha (su cámara la reescribe el controlador de persecución, así que son todas la cámara del juego: sirven de medida, no de ángulos distintos) | `vistas-antes/` y `vistas-despues/` |

---

## 6. Entrega

| Qué | Valor |
| --- | --- |
| Activo del coche | `assets/RedBull-Drive.glb` — **`e68bce2b582158b299ffb7556b635cfe8cba3ba1c0d407426e6797a942803202`** · 26 743 940 bytes (estado de partida: `a1d3f7ff…` · 26 595 516 bytes) |
| Circuito | `assets/BarcelonaMoto-Tutorial.glb` — `d9ceb75798958c8090eff9223230b9cb56b0e56e0491405b8b89c968f6fd7c06` · 188 646 600 bytes (**sin tocar**) |
| APK | [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk) — **`220db4eecaa490d24155335df46b7e5b54e00035f4271fd7701fa298f326f603`** · 247 605 857 bytes |
| Regresión completa | `./verify.sh` → **OK — 38 comprobaciones, 38 `ok`, 0 fallos obligatorios, 0 omitidas** |
| Aparato | `emulator-5556` (AVD `PRO`/Pixel 9a), lienzo horizontal 2424×1080 |
| Copia instalada | el `base.apk` extraído del dispositivo, idéntico al compilado (`huella_instalada`, `sha256` iguales) |

Las 38 comprobaciones incluyen las que vigilan lo que esta fase podía romper —`sonda_ruedas`,
`sonda_suspension`, `audit_ruedas_malla` (la prueba nueva), `sonda_camara`, `audit_camara`,
`sonda_impacto`, `sonda_conduccion` y la conducción real en el aparato (`camara_dispositivo`,
`camara_pixeles`)— y todas salen `ok`.

**El APK no es reproducible byte a byte**, y se ha medido: dos exportaciones de las mismas
fuentes dan **427 entradas con el mismo tamaño y el mismo CRC** (0 entradas distintas), los
mismos bytes comprimidos y **la misma longitud de archivo**, y sólo cambian las marcas de
tiempo del ZIP (`220db4ee…` contra `ebae52c4…`). El APK entregado es el de la corrida que
verifica. Es la misma conclusión que la fase 4 midió con otro contenido.

**Archivos de esta fase** (y los que no se tocan):

| Archivo | Qué cambia |
| --- | --- |
| `assets/RedBull-Drive.glb` | **sólo** la primitiva de goma de `wheel_rl` y `wheel_rr` (la llanta, el chasis, las delanteras, los nodos, los materiales y las texturas quedan igual) |
| `.tools/wheels/reparar_traseras.py` | nuevo: genera la funda y parchea el GLB a nivel binario |
| `.tools/recovery/audit_wheels_mesh.py` | nuevo: la medida **VISIBILIDAD** (2880 rayos por rueda) y el criterio que la hace obligatoria |
| `.tools/wheels/ver_la_goma.py` | nuevo: la misma prueba, suelta |
| `verify.sh` | se añade la comprobación obligatoria `audit_ruedas_malla` |
| `.tools/recovery/camera_pixels.py` | el instrumento de medida de la cámara: se descartan los candidatos que atraviesan la ventana (§4.5) |
| `scripts/`, `scenes/`, el resto de `assets/` | **sin tocar** (la reparación es del activo, no del código) |

La primera corrida de la batería de esta fase —antes del arreglo del instrumento de la
cámara— queda archivada con su fallo en
[`evidencia-camara/checks-fallo-camara-pixeles.tsv`](.tools/recovery/fase-traseras/evidencia-camara/checks-fallo-camara-pixeles.tsv)
(**37 `ok` y 1 `fallo`**, `camara_pixeles`), con el registro completo de esa corrida y el del
arreglo. La corrida que se entrega es la de arriba, entera y en verde.

---

## 7. Limitaciones pendientes (honestas)

1. **La llanta de las traseras conserva las cuatro grietas del mismo artefacto.** Es
   el mismo giro de sector del proyecto anterior, sobre la llanta: las cuatro piezas
   no cierran y por el eje **el 2,2 % de las direcciones atraviesan el disco** (16 de
   720 a r = 224,7 mm, en cuatro tramos periódicos cada 90°, ~8 mm de arco cada uno),
   frente al 0,3 % de la delantera (5 de 360). **No se ha reparado** y se razona por
   qué: (a) la llanta es una superficie *escaneada* que no se puede regenerar como
   sólido de revolución sin inventar su diseño (sus 4 piezas están a 130–200 mm unas
   de otras y abarcan a la vez buje, disco y barril: no es una llanta de cuatro
   cuñas), (b) el enunciado prohíbe sustituir piezas que no estén defectuosas y pide
   conservar el aspecto, y (c) el efecto visible es de **~1,6 píxeles** en el primer
   plano del juego (8 mm de arco sobre una rueda de 746 mm, con la rueda a ~150 px en
   `capturas-despues/parado-rueda_trasera.png`) y de **~0,4 píxeles** en la cámara de
   persecución del juego. Lo que sí se ha hecho es **medirlo y dejarlo en el
   informe**, y la prueba nueva (`visibilidad`) mide la superficie de la *goma*, que
   era lo que estaba roto.
2. **La goma nueva es una funda de cantos planos**, exactamente como la delantera
   (sección rectangular medida en ella). Un neumático real tiene el hombro redondeado;
   se ha preferido copiar la rueda aceptada antes que introducir una forma nueva. Si
   algún día se cambia el aspecto de las delanteras, hay que cambiarlo en las cuatro.
3. **Datos muertos en el activo**: el parche es aditivo, así que la goma vieja (los
   ocho gajos, ~95 KB por rueda) sigue en el BIN sin que nadie la referencie. El
   activo crece 148 KB (26 595 516 → 26 743 940 bytes). Se prefirió esto a rehacer el
   fichero: así el resto del BIN queda byte a byte igual y se puede demostrar.
4. **Sólo emulador** (`F1Recovery`, GPU del anfitrión, Apple M1): no hay pruebas en un
   teléfono físico, igual que en las fases anteriores.
5. **Comparación en movimiento cualitativa**: las capturas de recta y curva no están
   alineadas píxel a píxel entre antes y después (el coche avanza a distinto fotograma
   en cada pasada, aunque la sonda es determinista en posición, velocidad y pose). Las
   que se miden son las de parado.
6. Las traseras siguen siendo **más estrechas de goma** que las delanteras en
   proporción (141,5 mm de espesor radial frente a 172,9 mm) porque su llanta es más
   grande (barril a 0,621 R frente a 0,537 R): es una diferencia **del activo
   original** que se ha conservado (coincide con la proporción real de un F1: llanta
   de 18" sobre neumático de 720 mm ≈ 0,63 R).
