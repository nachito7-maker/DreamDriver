# Fase extra — Reparación de la forma de las ruedas del Red Bull

**Fecha:** 2026-10-14 · **Ámbito:** FORMA de los cuatro neumáticos del asset que usa el
juego (`assets/RedBull-Drive.glb`) · **No toca:** chasis, cámara, física, suspensión,
posición del coche, circuitos, HUD, controles ni la importación de Godot.

**Resumen.** La captura del juego mostraba las ruedas «deformadas, rotas o mal
ensambladas» y el diagnóstico es concluyente: **las delanteras eran óvalos y las
traseras tenían cuatro muescas**. Y no era cosa de Godot ni de la conversión: el
defecto **ya venía en el LOD0 del proyecto anterior**, con los mismos radios y las
mismas anchuras, y es la huella exacta de la reparación que aquel proyecto aplicó a
estas ruedas. Aquí se mide en la capa correcta (el GLB entregado), se corrige la
geometría del neumático con un torneado radial anclado en el talón, se repara el
reparto goma/llanta para que caiga en el barril y se verifica con la auditoría de
malla, las tres sondas existentes y la regresión completa.

| Medida de forma | Antes | Después |
| --- | --- | --- |
| Silueta del neumático `wheel_fl` (dispersión del radio por sector) | **7,94 mm** | **0,01 mm** |
| Silueta `wheel_fr` | **7,93 mm** | **0,08 mm** |
| Silueta `wheel_rl` | **12,20 mm** | **0,00 mm** |
| Silueta `wheel_rr` | **12,20 mm** | **0,00 mm** |
| Diámetros delanteros (A × B) | 761,5 × 746,0 mm (15,5 mm de diferencia) | 748,07 × 748,08 mm |
| Diámetros traseros | 749,2 × 749,2 mm, con 4 muescas de 12,2 mm cada 90° | 745,72 × 745,72 mm |
| Reparto goma/llanta contra el barril | a 32,2 / 25,4 / 42,5 / 42,5 mm | **0,0 mm** (cae en el barril) |
| Problemas de la auditoría de malla | **10** (salida 1) | **0** (salida 0) |
| Dispersión vertical de los cuatro fondos (sonda en ejecución) | 6,8 mm | **1,8 mm** |

---

## 1. Fase 1 — La solución del proyecto anterior, recuperada

La corrección anterior **está en el repositorio** del proyecto F1 (Unity):
`VehiclePrototypes/VEHICLE_INTEGRATION_REPORT.md` §11b y §11c, con los scripts
`VehiclePrototypes/tools/probe_wheel_fill.py`, `tools/wheel_lods.py` y
`tools/produce_fleet.py`, y las capturas `TestResults/audit_flota/*wheel*`,
`TestResults/meshy_ruedas/` y `TestResults/rueda_nueva/`. Lo que se documentó allí,
literal:

> **Detección honesta.** El sector cuenta como cubierto solo si su radio máximo llega al
> 93 % del radio del recorte (el mismo umbral que usa la sonda del FBX, para que pipeline
> y verificación no discrepen).
>
> **Relleno por simetría de revolución.** Se conserva el sector de 90° mejor cubierto y se
> rota tres veces más (90/180/270) sobre el eje de giro: la rueda queda entera con su
> propia geometría.
>
> **Radio medido de la corona.** Se mide la mediana de los máximos por sector y, si no
> cuadra, se escala la rueda en su plano alrededor del eje.
>
> **Prueba nueva.** `CadaRuedaEsUnNeumaticoEnteroNoUnRecorte` (EditMode, por carId) mide la
> banda en 12 sectores de 30° y exige que exista en 11 de 12.

Y la fila del Red Bull en su tabla de decisiones:

> | Red Bull | delanteras intactas | traseras: `bl` por **revolución**, `br` **donante de `bl`** |

**Esto es la clave del asunto, y se puede demostrar.** Dos de esas decisiones son
exactamente las que hoy se miden como defecto:

1. **El «relleno por simetría de revolución» deja cuatro costuras** —una cada 90°— y en
   cada costura los dos gajos no casan: se miden **12,20 mm** de muesca con periodicidad
   **exacta** de 90° (residuo 0,000 % al comparar la silueta consigo misma girada 90°).
   En el GLB entregado esos cuatro gajos siguen siendo **cuatro componentes separados
   incluso tras fundir vértices a 0,1 mm** (4 × 760 vértices), con un hueco irregular de
   10-15° en cada junta.
2. **El escalado «en su plano»** que ajustó el radio de la corona dejó las delanteras
   **ovaladas**: diámetros 761,51 × 745,97 mm, es decir **15,5 mm de diferencia** con un
   patrón cos 2θ.

**Por qué el proyecto anterior dio estas ruedas por buenas** —y esto también es
aritmética, no una opinión—: su criterio era cobertura «radio ≥ 93 % del radio de la
rueda». Las muescas traseras llegan a 366,4 mm sobre un radio de 378,6 mm, o sea
**0,968 R**, muy por encima de 0,93: la sonda contaba **72/72 sectores cubiertos** y no
veía la profundidad. La cobertura mide si *hay* banda; no mide si la banda es redonda.
Ninguna de las sondas posteriores (la caja envolvente de `audit_delivery.py`, la sonda de
ruedas y la de suspensión) ve la forma tampoco: **las tres daban `passed=true` con las
ruedas ovaladas y con muescas**. Eso es exactamente lo que ha añadido esta fase: una
medida que sí mira la forma.

## 2. Fase 2 — Auditoría del modelo actual

### 2.1 Qué carga el juego

`assets/RedBull-Drive.glb` (26,6 MB) → `assets/RedBull.tscn` → `scripts/gltf_model.gd`,
con las cinco mallas raíz `Body`, `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr`. Los
cuatro nodos de rueda cuelgan de la raíz **sin rotación ni escala** y su `translation.y`
es exactamente el radio inferior de cada neumático (0,38076 / 0,38116 / 0,37458 /
0,37458 m): es el contrato «el fondo del neumático está en y = 0» que leen
`car_controller._configure_suspension` (`_suspension_rest_y`) y `_update_visuals`
(`wheel.position.y = _suspension_rest_y[i] + suspension.offset[i]`). Los nombres internos
de las mallas (`mesh_wheel_bl_l0.001`, `mesh_wheel_br_l0.002`) ya delatan el origen: las
traseras son `bl` y una copia donante `br`, tal y como dice el informe anterior.

### 2.2 El defecto, medido

La auditoría nueva (`.tools/recovery/audit_wheels_mesh.py`) mide la silueta del radio por
sector dentro del GLB y encuentra, en el estado de partida, **10 problemas** (salida 1):

```
wheel_fl   R 380,97  silueta 7,94 mm   diámetros 761,51 × 745,97   talón 0,53 R
wheel_fr   R 381,56  silueta 7,93 mm   diámetros 762,33 × 747,42   talón 0,54 R
wheel_rl   R 378,60  silueta 12,20 mm  diámetros 749,17 × 749,17   talón 0,61 R
wheel_rr   R 378,60  silueta 12,20 mm  diámetros 749,17 × 749,17   talón 0,61 R
  - wheel_fl: silueta del neumático con 7.9 mm de dispersión (máx 7.6)
  - wheel_fl: diámetros desiguales: 761.5 y 746.0 mm (diferencia 15.5)
  - wheel_fl: el reparto goma/llanta está a -32.2 mm del barril (202.0 mm)
  - …ídem fr, rl y rr (rl/rr además con las cuatro muescas)
```

Y los detalles que explican el aspecto «roto»:

- **Traseras**: la silueta se repite cada 90° con muescas de 12,20 mm. El perfil fino a
  0,5° en una junta (alrededor de −81°) muestra el hueco: sectores de 10-15° con radios
  de 350-366 mm frente a los 378,6 mm del resto, con vértices dispersos. Tras fundir
  vértices a 0,1 mm la goma sigue partida en **4 componentes de 760 vértices**.
- **Delanteras**: recorrido suave en 2 lóbulos (cos 2θ) de 7,94 mm; la llanta tiene 2
  componentes y la goma 7 (dos grandes de 1814 y 635 vértices y cinco restos).
- **Reparto goma/llanta**: las caras cambian de material en 0,45 R (fl), 0,47 R (fr) y
  0,50 R (rl/rr) cuando el barril —la superficie cilíndrica interior de la llanta, medida
  con caras de normal radial— está en 0,53 / 0,54 / 0,61 / 0,61 R. Quedaban **25 a 42 mm
  del barril pintados de goma**, y de distinto tamaño delante y detrás: eso es lo que
  hace que la rueda parezca mal montada.
- Normales almacenadas frente a las geométricas: 0 % del área al revés (correcto) pero
  medianas de 5,2° (fl) a 9,0° (rl), que es el ruido del propio escaneo.
- Volumen firmado negativo en todas las piezas: es la convención del exportador con
  materiales de doble cara en **todo** el activo (chasis incluido), así que no se usa
  como criterio.

### 2.3 De dónde viene: el LOD0 del proyecto anterior

Se sonda el modelo de la flota anterior con `.tools/wheels/probe_source_wheels.py` (72
sectores de 5°, el mismo corte de 93 % de su sonda):

| fichero | rueda | R | anchura | cobertura | silueta p-p | residuo 90° |
| --- | --- | --- | --- | --- | --- | --- |
| `_backup_fill_20260921/redbull/model.fbx` (LOD0) | `x1_wheel_bl` | 378,60 mm | 457,5 mm | **72/72** | **12,20 mm** | **0,000 %** |
| ídem | `x1_wheel_br` | 378,60 mm | 457,7 mm | 72/72 | 12,20 mm | 0,000 % |
| ídem | `x1_wheel_fl` | 380,97 mm | 315,2 mm | 72/72 | **7,94 mm** | 1,290 % |
| ídem | `x1_wheel_fr` | 381,56 mm | 315,7 mm | 72/72 | **7,93 mm** | 1,246 % |
| `model_lod1.fbx` (LOD1) | `x1_wheel_bl` | 379,89 mm | 457,6 mm | 72/72 | 16,18 mm | 0,000 % |
| `model_lod2.fbx` (LOD2) | `x1_wheel_bl` | 382,27 mm | 458,1 mm | 72/72 | **22,85 mm** | 0,017 % |
| `model_lod2.fbx` (LOD2) | `x1_wheel_fl` | 382,08 mm | 315,7 mm | 71/72 | 15,05 mm | 1,459 % |

Los radios y las anchuras coinciden al milímetro con los del GLB entregado, y el patrón
de las cuatro muescas es idéntico: **la geometría que usa el juego es la del LOD0
anterior, sin retocar**. Además, **todos los LOD traen el mismo defecto** (LOD2 incluso
peor), así que la esperanza de «usar el LOD2 que estaba bien» no se sostiene en este
coche: lo que estaba bien en el proyecto anterior era el *diagnóstico* (la
«transformación de rueda corrupta en LOD0»), no el resultado de su reparación.

### 2.4 Qué NO era el defecto

- **No es Godot ni la importación**: la medida dentro del GLB y la medida en el motor
  coinciden en el mismo encuadre (`centro_mundo` idénticos al 0,1 mm), y el defecto ya
  está en el FBX de origen.
- **No son los pivotes ni las transformaciones**: la fase 2 los dejó centrados (0,0000 m),
  con el eje de giro lateral y sin órbita al girar; esta fase no los toca.
- **No son las sombras del entorno**: la auditoría mide la geometría (silueta, diámetros,
  piezas sueltas) y ahí están los 10 problemas; ninguna cámara ni luz se ha tocado.
- **No es el reparto de materiales de la fase 2** salvo en el talón, que sí se corrige (§3).

## 3. Fase 3 — Reparación

### 3.1 Dónde se corrige

En el **asset** (`assets/RedBull-Drive.glb`), no en ejecución: es un defecto de geometría
del activo. La corrección es un **torneado radial del neumático anclado en el talón**:
para cada vértice de la goma,

```
r' = min( r + (R_objetivo − P(θ)) · t , R_objetivo )      t = recorte((r − r_talón)/(P(θ) − r_talón), 0, 1)
```

- `P(θ)` es la silueta **medida** del sector (720 sectores de 0,5°, perfil interpolado
  entre centros de sector y sin suavizar) de la banda exterior (`r ≥ 0,90 R`).
- `R_objetivo` es la **mediana** del perfil medido (374,04 / 375,34 / 372,86 / 372,86 mm):
  es el radio que el pipeline anterior ajustó (0,376 m) y el que el propio activo declara
  en sus tres anchuras.
- `r_talón` es el **barril medido con el mismo algoritmo que el auditor**, de modo que en
  el talón (t = 0) no se mueve nada: el asiento del neumático sobre la llanta queda
  intacto y no puede abrirse una rendija.
- El **tope** en `R_objetivo` es imprescindible: en los bordes de una muesca el perfil
  interpolado cae por debajo del radio de un vértice vecino y sin él la corrección lo
  empujaría **por fuera** del objetivo (se midieron 20 mm de protrusión antes de ponerlo).
- El perfil axial (corona, hombros, anchura) **no se toca**: la corrección depende solo
  del ángulo.
- Después se **reasienta la rueda**: la `translation.y` de cada nodo pasa a valer su nuevo
  radio inferior, para que el fondo del neumático siga en y = 0 del modelo (el contrato
  que lee el controlador), y el pivote se deja en el centro de la malla.

Y el **reparto de materiales** se rehace por el talón medido: la llanta coge todo lo que
queda dentro del barril (barril, radios y buje) y el neumático todo lo de fuera (flanco y
banda). La frontera cae en 0,54 / 0,54 / 0,62 / 0,62 R.

### 3.2 Dos intentos fallidos, dichos como fueron

El mismo script (`fix_redbull_wheels.py`) ya existía de un intento anterior y **no había
funcionado** (la silueta pasó de 11,39 a 11,21 mm). La causa merece quedar escrita porque
es fácil repetirla: calculaba el factor radial como `objetivo / silueta_SUAVIZADA`. Al
dividir por el perfil suavizado, lo que queda es justo lo que el suavizado había quitado
(`nuevo = objetivo + (P − P_suave)`), así que el defecto medido sobrevivía. La corrección
correcta divide por el perfil **medido**. Y el primer intento de esta sesión añadió por su
cuenta una protrusión de 20 mm por el rebasamiento descrito arriba; también está corregido
y verificado.

### 3.3 Qué se cambió, fichero a fichero

| Fichero | Cambio |
| --- | --- |
| `assets/RedBull-Drive.glb` | **El activo entregado.** Posiciones de los vértices de los cuatro neumáticos (torneado radial) y `translation.y` de los cuatro nodos de rueda; más el reparto de caras goma/llanta por el barril. Nada más: chasis, texturas, UVs, topología, nombre de nodos, transformaciones y jerarquía quedan intactos. |
| `.tools/wheels/fix_redbull_wheels.py` | La reparación (Blender sin interfaz): torneado, barril medido, reparto de materiales, reasiento y recentrado del pivote, con informe propio. |
| `.tools/recovery/audit_wheels_mesh.py` | La auditoría de forma que mide lo que las sondas de caja no ven (silueta por sector, diámetros, corona, normales almacenadas, barril, piezas sueltas, protrusiones, reparto de materiales). Sale con código ≠ 0 si algo incumple. |
| `.tools/wheels/probe_source_wheels.py` | La sonda que mide la forma en los FBX del proyecto anterior (LOD0/LOD1/LOD2) y permitió cerrar la causa raíz. |
| `.tools/recovery/fase-ruedas/comparar.py` | La comparación medida de capturas (diferencia por píxel + montaje lado a lado). |
| `verify.sh` | Añade `audit_ruedas_malla`: la forma entra en la regresión (antes ninguna comprobación de la cadena la miraba). |
| `.tools/recovery/fase-ruedas/INFORME-FASE-RUEDAS.md` | Este informe. |
| `.tools/wheels/backup-antes-redondeo/` | **Copia de recuperación** del estado de partida (GLB, `.import`, auditoría, informe y huellas) con instrucciones para volver. |

La corrección **no** usa offsets arbitrarios, **no** cambia cámara, física, suspensión ni
la posición global del coche, y **conserva** la corrección de la altura de las ruedas y la
suspensión de las fases anteriores (§4.3 lo comprueba).

## 4. Fase 4 — Validación

### 4.1 El activo entregado (auditoría de malla, dentro del GLB)

```
ACTIVO assets/RedBull-Drive.glb
rueda          R mm    ancho     diám.A     diám.B   silueta  corona    área↻    talón  piezas
wheel_fl     374.05   315.19     748.07     748.08      0.01    0.00     0.0%   0.54 R       2
wheel_fr     375.34   315.68     750.55     750.46      0.08    0.02     0.0%   0.54 R       2
wheel_rl     372.89   457.48     745.72     745.72      0.00    0.00     0.0%   0.62 R       4
wheel_rr     372.89   457.68     745.72     745.72      0.00    0.00     0.0%   0.62 R       4

FORMAS OK: las cuatro ruedas pasan los criterios de forma
```

Las anchuras son **exactamente** las de partida (315,19 / 315,68 / 457,48 / 457,68 mm) y
los pivotes siguen en el centro de la malla.

### 4.2 El activo entregado (auditoría de entrega, caja envolvente)

`.tools/recovery/audit_delivery.py` sale con código 0: fondos de las cuatro ruedas
coplanares en y = 0, pivotes centrados, eje de giro lateral, suelo del chasis por encima
del plano de contacto. `wheel_rr`: `fondo_m=0.0`, `pivote_m=[0,0,0]`, `radio_m=0.37286`,
`anchura_m=0.45768`.

### 4.3 El coche montado (sondas en ejecución)

**Sonda de ruedas** (`scripts/car_wheel_probe.gd`): `RUEDAS passed=true errores=0`. Las
cuatro ruedas con pivote 0,0000 m, eje de giro dominante **X lateral**, y **órbita 0,0000 m**
en las cuatro combinaciones de dirección y giro probadas (0,00 / 0,30 de dirección × 0,00 /
1,57 / 3,00 de giro). Comparado con el mismo sondeo antes de la reparación (mismo punto de
pista, `centro_mundo` idénticos al 0,1 mm):

| rueda | diámetros antes | diámetros ahora | radio antes → ahora | aire fondo-asfalto antes → ahora |
| --- | --- | --- | --- | --- |
| fl | 761,5 × 746,0 | **748,1 × 748,1** | 0,3808 → 0,3740 | +0,3 → −3,7 mm |
| fr | 762,3 × 747,4 | **750,5 × 750,5** | 0,3812 → 0,3753 | −0,5 → −3,6 mm |
| rl | 749,2 × 749,2 | **745,7 × 745,7** | 0,3746 → 0,3729 | −6,5 → −5,4 mm |
| rr | 749,2 × 749,2 | **745,7 × 745,7** | 0,3746 → 0,3729 | −5,0 → −5,4 mm |

Los dos diámetros coinciden en las cuatro ruedas (antes no) y los cuatro fondos pasan de
**6,8 mm de dispersión a 1,8 mm**: quedan más coplanares que antes.

**Sonda de suspensión** (`scripts/suspension_probe.gd`): `SUSPENSION passed=true
errores=0`, con las diez pruebas de la fase 3. Lo importante de la penetración:

```
== 9. PENETRACIÓN  muestras geométricas=3284 (descartadas 0 por suelo lejano y 68 por canto de bordillo)
   garantía estructural (plano del chasis + recorrido − asfalto medido): -0.00 mm
```

Es decir: **las ruedas no atraviesan el asfalto** en ninguna de las 3284 muestras, y en
reposo el recorrido residual es 0,0 mm y el aire fondo-asfalto 0,1 mm. La suspensión sigue
funcionando (en frenada las delanteras se comprimen hasta +10,3 mm y las traseras se
extienden −10,9; en el resalto de 30 mm el recorrido llega a ±35 mm). Que las ruedas giren
sobre sus ejes lo comprueba la propia sonda con la misma transformación que usa
`_update_visuals` (órbita 0,0000 m) y la dirección en el eje delantero con el giro aplicado.

### 4.4 Capturas comparativas

Se han capturado **42 vistas con la misma cámara, el mismo escenario y el mismo punto de
pista** antes y después (sonda de suspensión: reposo, aceleración, frenada, curva moderada,
curva rápida y resalto × cámara del juego, frontal, lateral, trasera baja y las cuatro
ruedas), más 18 vistas de la sonda de ruedas. Los montajes lado a lado y la medida por
píxel están en `.tools/recovery/fase-ruedas/comparativa/` (log:
`logs/comparativa.log`):

| captura | diferencia media | píxeles cambiados | caja de lo cambiado |
| --- | --- | --- | --- |
| `aceleracion-rueda_delantera_der` | 28,74/255 | 26,19 % | 0,38 → 1279,587 |
| `curva_rapida-rueda_delantera_der` | 24,88 | 24,27 % | 0,52 → 1279,609 |
| `reposo-lateral` | **0,17** | 0,17 % | 430,52 → 815,411 |
| `reposo-frontal` | **0,14** | 0,12 % | 511,52 → 781,457 |

Dos lecturas honestas de esta tabla:

1. **En reposo el cambio es pequeño y está en las ruedas**: en `reposo-frontal` los
   píxeles que cambian están en la banda x 511-781 (las ruedas) y no en la carrocería; en
   `reposo-lateral`, en la banda x 430-815. Un neumático de 750 mm visto a varios metros
   ocupa pocos píxeles, así que una corrección de 12 mm es sutil **en el encuadre del
   juego**; el sitio donde se nota a simple vista es la rueda de cerca.
2. **En movimiento la diferencia mezcla la fase de giro del neumático** (el dibujo de la
   banda está en otro ángulo en el instante de la captura), así que esas diferencias
   grandes (28,7) **no se pueden atribuir todas a la reparación**. La prueba de forma es
   la de §4.1, que mide la malla, no la imagen.

## 5. Fase 5 — Regresión y entrega

`./verify.sh` con el emulador del perfil 2 (`PRO` = Pixel 9a, 1080 × 2424, 420 dpi,
`emulator-5556`):

```
resultado: OK
comprobaciones: 34 ok · 0 fallo · 0 omitida
fallos obligatorios: []
```

Salida completa: [`logs/verify.log`](.tools/recovery/fase-ruedas/logs/verify.log) e
informe estructurado: `.tools/recovery/integral/verificacion-integral.json`
(`fecha 2026-10-14T20:51:10`, `resultado: OK`). Incluye las 15 sondas del juego (pista,
materiales, runtime, **ruedas**, **suspensión**, controles, cronómetro, inventario de
colisiones, escapatorias, agarre, dirección, sentido del mando, movilidad fuera de pista,
impacto y la **vuelta completa de conducción**, 537 s de simulación), las tres auditorías
(de materiales, entrega y **forma de ruedas**), la exportación y firma del APK, el
empaquetado contra el preset, la instalación sin incremental, la comprobación de que la
huella del APK instalado coincide con la del compilado, el arranque, el registro limpio,
la pantalla y el lienzo, el toque multitáctil medido en el vídeo de la propia pantalla, el
cronómetro y los fotogramas por segundo del anfitrión.

Es **una comprobación más que la corrida de la fase anterior** (33 → 34) porque esta fase
añade `audit_ruedas_malla`: sin ella, una rueda ovalada o con muescas pasaba la regresión
entera con salida 0.

**APK:** [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
`sha256 f35a3413197e921c7e9d96291977728756090c9480ff116662a9f16228b8008e` ·
247 695 969 bytes · mtime 2026-10-14 20:44:37 · firmado en depuración, arm64-v8a. La
comprobación `huella_instalada` confirma que el `base.apk` extraído del aparato coincide
con el compilado.

**Que las ruedas reparadas viajan dentro del APK** (comprobación de cierre, medida): el APK
no lleva el `.glb` crudo sino el recurso que importa Godot, y ese fichero es el mismo en los
dos sitios:

```
APK      assets/.godot/imported/RedBull-Drive.glb-a0f87076c316669302e4e1e226512561.scn
         sha256 463a462b0ff4692018f631c6b65953e851b4706a80c4c59eacaf66749d2eeb5a   5 364 008 bytes  20:44
local    .godot/imported/RedBull-Drive.glb-a0f87076c316669302e4e1e226512561.scn
         sha256 463a462b0ff4692018f631c6b65953e851b4706a80c4c59eacaf66749d2eeb5a   5 364 008 bytes  20:22
```

La cadena entera queda cerrada: `assets/RedBull-Drive.glb` (`a1d3f7ff…`) → recurso
importado (`463a462b…`, generado a las 20:22 al reimportar el activo reparado) → el mismo
fichero dentro del APK entregado (`463a462b…`, 20:44). El `.import` de la fuente declara el
md5 `ba41b63c9e831a9130f23caacab254ac`, que es el del activo reparado.

## 6. Limitaciones pendientes (honestas)

1. **El modelo de origen sigue con el defecto.** El asset entregado es el que usa el
   juego, pero cualquier reconstrucción del coche desde
   `VehiclePrototypes/_backup_fill_20260921/redbull/model*.fbx` (o desde el pipeline de
   flota anterior) volvería a traer las muescas y el óvalo. La corrección de raíz sería
   una comprobación de **redondez** en `produce_fleet.py` junto a la de cobertura, y
   aplicarla a los cuatro LOD del coche. No se ha hecho aquí porque el encargo era el
   asset del juego y ese pipeline pertenece al proyecto anterior.
2. **Los cuatro gajos traseros siguen siendo componentes separados** (no soldados). No se
   ha soldado a propósito: están a 12 mm, una fusión a 0,2 mm no los cerraría y solo
   cambiaría la numeración de la malla (y con ella las costuras de UV). Ahora sus bordes
   caen **todos** en el mismo radio (0,00 mm de dispersión) y la auditoría no encuentra
   piezas anidadas ni protrusiones, así que la junta es geométricamente continua.
3. **No se han recalculado las normales.** El torneado cambia la pendiente de la
   superficie en las muescas (≤ 3 % del radio) y las normales almacenadas siguen siendo
   las del escaneo: el ángulo entre la normal almacenada y la geométrica sube de 5,2° a
   6,3° (fl) y de 9,0° a 10,0° (rl) de mediana. La auditoría solo exige que no haya
   normales **al revés**, y no hay ninguna (0,0 % del área), pero el sombreado en las
   costuras queda tan suave como venía del escaneo.
4. **El neumático queda con el radio mediano**: crece en las muescas y en el lado estrecho
   del óvalo y mengua en el lado ancho (delanteras: 761,5 → 748,1 mm de diámetro; traseras:
   749,2 → 745,7). Es la rueda que el pipeline anterior declaraba (0,376 m de radio) y la
   que hace que la silueta sea una circunferencia, pero significa que el coche calza unas
   ruedas 6 mm menores que el aspecto que tenía. El asiento en el suelo y la altura de
   marcha se comprueban en §4.2 y §4.3.
5. **No se ha medido el aspecto a ojo** (quien firma esto mide, no mira): la valoración
   visual queda en los montajes de `.tools/recovery/fase-ruedas/comparativa/`, que están
   ahí para que la mire una persona.
6. **El reparto de materiales se lleva al barril** (0,54 / 0,62 R), lo que pinta de metal
   la parte del neumático que queda **dentro** del barril de la llanta. Es geometría que
   no se ve desde fuera, y es lo que exige la frontera física, pero conviene saberlo.
7. **El cuerpo del coche se reexporta** porque comparte fichero con las ruedas: Blender
   reescribe el GLB entero y el `Body` queda con **98 608 vértices en lugar de 98 607** por
   la reserialización. La geometría es la misma —caja envolvente idéntica al 0,00001 m,
   huella de materiales idéntica (`2829876cd51f5e8f`) y las mismas 4 texturas— y la
   comparación de capturas no encuentra píxeles cambiados fuera de las ruedas
   (`reposo-frontal` cambia solo en la banda x 511-781), pero el fichero no es idéntico
   fuera de las ruedas y no se afirma que lo sea.

## 7. Cómo se reproduce

```bash
# 1. Auditar la forma del activo entregado (sale ≠ 0 si hay óvalo, muescas o mal montaje)
python3 .tools/recovery/audit_wheels_mesh.py assets/RedBull-Drive.glb

# 2. Medir la forma en el modelo de origen del proyecto anterior (LOD0/LOD1/LOD2)
blender --background --factory-startup --python .tools/wheels/probe_source_wheels.py -- \
    VehiclePrototypes/_backup_fill_20260921/redbull/model.fbx \
    VehiclePrototypes/_backup_fill_20260921/redbull/model_lod2.fbx

# 3. Reparar (escribe un candidato; el script imprime silueta antes/después por rueda)
blender --background --factory-startup --python .tools/wheels/fix_redbull_wheels.py -- \
    assets/RedBull-Drive.glb /tmp/RedBull-ruedas-redondas.glb .tools/wheels/wheels-beads.json
python3 .tools/recovery/audit_wheels_mesh.py /tmp/RedBull-ruedas-redondas.glb

# 4. Verificar en el motor y comparar las capturas
GODOT=.tools/godot/Godot.app/Contents/MacOS/Godot
"$GODOT" --path . --script scripts/car_wheel_probe.gd
"$GODOT" --path . --script scripts/suspension_probe.gd
python3 .tools/recovery/fase-ruedas/comparar.py

# 5. Regresión completa
SERIAL=emulator-5556 ./verify.sh

# 6. Volver atrás
cp .tools/wheels/backup-antes-redondeo/RedBull-Drive.glb assets/
shasum -a 256 -c .tools/wheels/backup-antes-redondeo/SHA256SUMS
```

## 8. Huellas

| Fichero | SHA-256 antes | SHA-256 después |
| --- | --- | --- |
| `assets/RedBull-Drive.glb` | `9c601ee17243a71248575d2256463de54630416b69ac470427729efcd102aa9f` | `a1d3f7ff073bd9bb33ae6f3050b08db3c74a04e1fc0a5e3524b860a9681d0c8a` |
| `assets/BarcelonaMoto-Tutorial.glb` (intacto) | `d9ceb75798958c8090eff9223230b9cb56b0e56e0491405b8b89c968f6fd7c06` | igual |
| `build/android/F1OneShot-BarcelonaMoto.apk` | — | `f35a3413197e921c7e9d96291977728756090c9480ff116662a9f16228b8008e` |
| Copia de recuperación del estado de partida | — | `.tools/wheels/backup-antes-redondeo/` (`9c601ee1…`) |

## 9. Resultado de la regresión

`SERIAL=emulator-5556 ./verify.sh` → **`EXIT_VERIFY=0`**, con este detalle (34 filas de
`.tools/recovery/integral/checks.tsv`, todas en `ok`):

| Comprobación | Tiempo | Comprobación | Tiempo |
| --- | --- | --- | --- |
| `sonda_pista` | 1 s | `audit_materiales` | 0 s |
| `sonda_materiales` | 6 s | `audit_entrega` | 2 s |
| `sonda_runtime` | 13 s | **`audit_ruedas_malla`** | 1 s |
| `sonda_ruedas` | 16 s | `compilar` (APK) | 11 s |
| `sonda_suspension` | 53 s | `firma` | 0 s |
| `sonda_controles` | 8 s | `huella_apk` | 1 s |
| `sonda_vuelta` (cronómetro) | 0 s | `empaquetado` | 0 s |
| `sonda_inventario` (colisiones) | 5 s | `dispositivo` | 0 s |
| `sonda_escapatorias` | 4 s | `instalar` | 7 s |
| `sonda_agarre` | 22 s | `huella_instalada` | 4 s |
| `sonda_direccion` | 56 s | `arranque` | 30 s |
| `sonda_sentido` | 12 s | `registro_limpio` | 0 s |
| `sonda_movilidad` | 322 s | `pantalla` | 1 s |
| `sonda_impacto` | 22 s | `lienzo` | 1 s |
| **`sonda_conduccion`** (vuelta completa) | 537 s | `toque_jar` | 2 s |
| | | `toque` (multitáctil real) | 319 s |
| | | `cronometro` | 4 s |
| | | `lienzo_final` | 1 s |
| | | `fps_anfitrion` | 20 s |

Conducción, colisiones, controles, cronómetro y sectores siguen funcionando: la vuelta
completa de 537 s da `FULL_LAP passed=true`, las cuatro ruedas giran (`rotating=true` en
`sonda_runtime`), el mando gira el coche al lado correcto (`sonda_sentido`: −77,6° a la
derecha, +83,4° a la izquierda) y la dirección no cambia de sentido frenando en curva
(`sonda_direccion`: 0 cambios).
