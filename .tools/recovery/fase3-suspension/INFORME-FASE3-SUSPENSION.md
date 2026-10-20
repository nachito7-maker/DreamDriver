# FASE 3 — Suspensión funcional del Red Bull

Cierre: 14 de octubre de 2026. Continuación de
[`INFORME-FASE2-RUEDAS.md`](../fase2-ruedas/INFORME-FASE2-RUEDAS.md).

**Resumen.** El coche tenía las cuatro ruedas corregidas pero **rígidas**: no existía
ningún recorrido de suspensión. Ahora cada rueda tiene su propio recorrido vertical
independiente (35 mm de compresión, 30 mm de extensión) resuelto a partir de un rayo
bajo cada rueda, y el chasis se apoya en las cuatro suspensiones mediante el equilibrio
de muelles con la transferencia de carga real. Al frenar se hunden las ruedas delanteras
y se extienden las traseras; al acelerar, al revés; en curva se comprimen las exteriores.
La geometría de la fase 2 se conserva al milímetro (desvío en planta 0,0000 mm, fondo de
cada neumático a 0,1 mm del asfalto parado) y `./verify.sh` sigue en verde.

---

## 1. Fase 1 — auditoría: cómo se movía el coche

Comprobado en el código, no supuesto:

| Pregunta | Respuesta medida |
| --- | --- |
| Arquitectura física | `CharacterBody3D` (`scripts/car_controller.gd`, línea 1) con `motion_mode = MOTION_MODE_GROUNDED`, `floor_snap_length = 0,65` y **una sola caja de colisión** de 1,20 × 0,55 × 3,40 m en `y = 0,29`, creada en `scripts/race.gd` (`_build_car`). El movimiento lo integra `move_and_slide()` + `apply_floor_snap()`. |
| Contacto con el asfalto | No lo deciden las ruedas: lo decide la **caja**. Las ruedas se medían con cuatro rayos hacia abajo en puntos **fijos** (±0,85, 0, −1,5 / +1,95) en `_sample_ground()`, que devolvían `wheel_contacts`, la normal media y la altura media. |
| Altura del terreno bajo cada rueda | Sólo se guardaba la **media** de los cuatro impactos (`_ground_height`); las cuatro alturas por separado se descartaban. |
| Cabeceo, balanceo y altura del chasis | La altura era la media de los contactos; la actitud salía de la **normal media** del suelo. El balanceo y el cabeceo de suspensión eran **prefijados a mano** (`_body_roll`, `_body_pitch`, topados en ±2°) y se aplicaban a la malla del chasis. |
| Posición de las ruedas visuales | Sólo se escribía su `basis` (dirección × giro). Su `position` no se tocaba nunca: las cuatro iban rígidas al modelo. |
| Componentes de suspensión reutilizables | Ninguno. No había nada parecido en el proyecto. |
| Limitación de la arquitectura | Con una caja y un plano medio no hay forma de que una rueda suba sin que suba el coche entero. Por eso la fase 2 midió hasta **6,5 mm de aire** bajo una rueda sobre badenes fuertes, y por eso la salida elegida entonces fue no inclinar el modelo con el balanceo (con ruedas rígidas, inclinarlo las separaba del asfalto 3,2 cm acelerando y 8,4 cm en curva). |

## 2. Fase 2 — diseño elegido y por qué

**Solución: se conserva la conducción y se añade un modelo de cuatro muelles.**

La alternativa "de libro" —un vehículo de cuatro rayos de verdad, con fuerzas por rueda y
chasis integrado por física— obliga a rehacer el sistema de conducción completo (fuerzas
longitudinales y laterales, guiñada, deriva, agarre por superficie, choques), que es justo
lo que las fases 1 y 2 dejaron verificado con sondas. Sustituirlo no era necesario para
resolver lo que se pide (recorrido por rueda y chasis que se apoya en él) y habría puesto
en riesgo todo lo ya medido. El coste de la solución elegida es un archivo nuevo y tres
funciones del controlador; el riesgo sobre la conducción, cero (no se toca ni una línea de
fuerzas, dirección, cámara, colisiones ni controles).

El modelo (`scripts/wheel_suspension.gd`) es el equilibrio de un cuerpo apoyado en cuatro
muelles lineales con amortiguador:

```
u_i = s_i − (A + B·x_i + C·z_i)        recorrido de la rueda i (+, comprimida)
Σ k_i·u_i     = 0                     equilibrio vertical
Σ k_i·u_i·z_i = m·a_x·cg              momento de cabeceo (acelerar / frenar)
Σ k_i·u_i·x_i = m·a_y·cg              momento de balanceo (curva)
```

`s_i` es la altura del asfalto bajo cada rueda (un rayo por rueda), `(A, B, C)` el plano
del chasis —altura y las dos pendientes— y `k_i` la rigidez del muelle de esa rueda. Las
tres incógnitas salen de resolver ese sistema 3×3, que es a la vez el ajuste por mínimos
cuadrados ponderado por los muelles. De ahí salen, **sin ningún valor prefijado**, el
cabeceo y el balanceo: al acelerar el momento es positivo y el morro sube; al frenar se
hunde; en curva la carga viaja al lado exterior y esa rueda se comprime.

Tres decisiones más, todas para que la rueda no atraviese el asfalto:

1. **La rueda se coloca en el residuo medido.** `offset_i` es exactamente `s_i` menos el
   plano del chasis en su vertical, así que el fondo del neumático cae sobre el asfalto
   medido por construcción (verificado: hueco estructural ≥ −0,00 mm en toda la sesión).
2. **Topes con subida del chasis.** Si un badén agota los 35 mm de compresión, el chasis
   sube lo que haga falta: es lo que hace un coche real cuando la suspensión tope. La
   extensión se limita a 30 mm y la rueda queda colgando, nunca por debajo del firme.
3. **La rueda no se inclina con la carrocería.** Se deshace el balanceo de suspensión en
   la orientación de cada rueda (la inclinación del asfalto sí se conserva), que es lo que
   hace una suspensión real. Sin esto, con 2° de balanceo el borde del neumático se hundía
   5 mm; con 6,2° de peralte, hasta 25 mm (medido: 25,3 mm frente a los 25,4 mm que predice
   `anchura/2 · sen(inclinación)`).

## 3. Fase 3 — qué se ha tocado

| Archivo | Cambio |
| --- | --- |
| [`scripts/wheel_suspension.gd`](scripts/wheel_suspension.gd) | **Nuevo.** El modelo completo: cargas, equilibrio 3×3, filtros del amortiguador, topes y diagnóstico (`stats()`). |
| [`scripts/suspension_probe.gd`](scripts/suspension_probe.gd) | **Nuevo.** Las diez pruebas de la fase 4 con mediciones y código de salida. |
| [`scripts/car_controller.gd`](scripts/car_controller.gd) | `const SuspensionScript`; variables de la suspensión; `_configure_suspension()` (nueva) con la geometría medida del modelo; `_sample_wheel_contacts()` (nueva) sustituye a la segunda muestra de suelo: un rayo por rueda desde +0,8 m hasta −0,9 m con filtro de cordura; `_update_visuals()` usa la pose de la suspensión y aplica a cada rueda su recorrido vertical; se eliminan `_body_roll`/`_body_pitch`; `recover_to()` reinicia la suspensión. |
| [`scripts/car_wheel_probe.gd`](scripts/car_wheel_probe.gd) | La línea de diagnóstico imprime el recorrido por rueda y el cabeceo del chasis en lugar de las dos variables prefijadas que ya no existen. |
| [`verify.sh`](verify.sh) | Nuevas comprobaciones obligatorias `sonda_suspension` y `empaquetado`. |
| [`export_presets.cfg`](export_presets.cfg) | `scripts/wheel_suspension.gd` entra en el `include_filter`: sin eso el script no viajaba en el APK (§6). |
| [`.tools/recovery/check_packaged.py`](.tools/recovery/check_packaged.py) | **Nuevo.** Audita el contenido del APK contra el preset y contra los `res://` que precargan los scripts y escenas empaquetados. |

**Nada más se ha tocado.** No se ha modificado el modelo 3D (`assets/RedBull-Drive.glb`),
ni los pivotes, ni las transformaciones de la fase 2, ni la cámara, ni el circuito, ni las
colisiones, ni la dirección, ni los controles, ni las fuerzas del coche.

## 4. Parámetros físicos y su justificación

| Parámetro | Valor | Justificación |
| --- | --- | --- |
| Masa | 798 kg | La que declara el coche (`car_controller.mass_kg`). |
| Reparto delantero | 46 % | El que declara el coche (`front_weight_fraction`). Medido de nuevo por la sonda: 3601 N delante / 4227 N detrás = **0,460**. |
| Centro de gravedad | 0,33 m | El que declara el coche (`cg_height_m`). |
| Batalla / vías | 3,4637 m / 1,8605 m / 1,7674 m | **Medidas en el modelo** (posiciones de los cuatro nodos de rueda), no los valores nominales del export: son las que reparten la carga. |
| Rigidez de muelle | 150 kN/m delante, 130 kN/m detrás | Rango de barras de torsión de un monoplaza (100–200 N/mm). Con los repartos reales, el hundimiento de diseño es 12,0 mm delante y 16,3 mm detrás: entra en el recorrido y es el que ya trae el modelo entregado. |
| Recorrido | 35 mm de compresión, 30 mm de extensión | Comparables a los ~30 mm de bump y 30 mm de rebote de un F1. |
| Amortiguador | τ = 50 ms en la actitud (ζ ≈ 0,7) y en la compresión | Con la masa de cada esquina (m/4 ≈ 200 kg) y k = 150 kN/m, el amortiguamiento crítico es 10 954 N·s/m; con ζ = 0,7 sale τ = c/k ≈ 50 ms. |
| Regularización | 150 000 · (3 − ruedas cargadas) | Con menos de tres ruedas sosteniendo el coche el plano no está determinado: la actitud la fija la inercia del chasis y el modelo tira hacia la actitud anterior en vez de inventar una inclinación con un momento que no tiene con qué equilibrarse. |
| Guardas numéricas | plano a ≤ 0,5 m del asfalto medido, pendientes ≤ 8,6°, actitud de suspensión ≤ 2,9°, rechazo de rayos a más de 0,4 m de la muestra anterior y fuera de [origen − 1,0 m, origen + 0,5 m] | Ninguna solución absurda puede llegar a la geometría del coche. |

Dos observaciones de física que conviene dejar escritas, porque son el resultado y no un
defecto: con barras de torsión de monoplaza el **cabeceo y el balanceo son pequeños**
(décimas de grado en frenada y aceleración, 0,15–0,34° en curva) y lo que se ve trabajar es
el **recorrido por rueda** (hasta 10 mm en frenada y los 35 mm en un badén). Y la
transferencia de carga es pequeña porque el centro de gravedad está bajo (0,33 m) y la
batalla es larga: a 1,3 g la carga cambia ~500 N por rueda, que con 150 kN/m son ~3 mm.

## 5. Fase 4 — las diez pruebas

Sonda: `scripts/suspension_probe.gd` (obligatoria en `verify.sh`). Registro completo:
[`sonda.log`](sonda.log), cifras en [`medidas.json`](medidas.json), capturas en
[`vistas/`](vistas).

| # | Prueba | Resultado medido |
| --- | --- | --- |
| 1 | Parado sobre superficie plana | Recorrido máximo **0,0 mm**, fondo del neumático a **0,1 mm** del asfalto, pose a **0,00°** del plano de la calzada, cargas 3601/4227 N (reparto 0,460). |
| 2 | Aceleración en recta | 44,9 → 115,4 km/h, 11,49 m/s². Cabeceo de suspensión **+0,126°** (morro arriba). Delanteras **−3,9 / −3,8 mm** (se extienden), traseras **+4,7 / +4,4 mm** (se comprimen). |
| 3 | Frenada en recta | 108,2 → 0,0 km/h, 32,99 m/s². Cabeceo **−0,305°** (morro abajo). Delanteras **+8,8 / +10,3 mm** (se comprimen), traseras **−10,6 / −10,8 mm** (se extienden). |
| 4 | Curva a velocidad moderada | 69,8 km/h, **0,51 g**, 582 muestras. Balanceo de suspensión **+0,147°** (opuesto al lado exterior). Recorrido: exterior izquierdo 1,37 mm / interior derecho −0,99 mm (2,36 mm de transferencia). |
| 5 | Curva a velocidad elevada | 98,6 km/h, **1,07 g**, 955 muestras. Balanceo **+0,340°**. Izquierda 0,61 mm / derecha −1,23 mm. |
| 6 | Paso por irregularidades | Resalto de prueba de **30 mm** (0,34 × 4,00 m, alineado con el coche, creado por la sonda; **no existe en el juego**) bajo las dos ruedas izquierdas: izquierdas hasta **+35,0 mm** (tope de compresión), derechas hasta **−30,0 mm** (tope de extensión), chasis 133,7 mm por encima de la calzada al subir el escalón. |
| 7 | Compresión y extensión de cada rueda | Las cuatro ruedas se comprimen y se extienden en la sesión: fl +35,0/−30,0; fr +10,3/−30,0; rl +35,0/−30,0; rr +35,0/−30,0 mm. Ninguna sale de sus topes. |
| 8 | Sin vibraciones ni saltos | Crucero a 59,5 km/h, 3 s a 60 Hz: segunda diferencia de la altura del chasis **pico 0,143 mm/fotograma²** (tope 1,0) y **RMS 0,033 mm** (tope 0,25). |
| 9 | Sin penetración | 3284 muestras de geometría. Fondo del neumático contra el asfalto (descontada la inclinación del propio firme): **peor −0,5 mm**. Garantía estructural —plano del chasis + recorrido frente al asfalto medido—: **−0,00 mm** en toda la sesión. |
| 10 | Posición correcta de los neumáticos | Desvío en planta **0,0000 mm** en las cuatro, pivote descentrado **0,0000 mm**, órbita al girar **0,0000 mm**, radios 0,3746–0,3812 m, anchuras 0,3152–0,4577 m. Idéntico a la fase 2. |

Las nueve pruebas que dependen de la conducción se hacen con las entradas reales del mapa
de acciones (las mismas que pisa un dedo) y persecución sobre la trazada; la sonda termina
con código distinto de cero si algo falla. Resultado: `SUSPENSION passed=true errores=0`.

### Antes y después

| Medida | Antes (fase 2, ruedas rígidas) | Después (fase 3) |
| --- | --- | --- |
| Recorrido vertical de cada rueda | Ninguno (0 mm en las cuatro; la rueda iba rígida al modelo) | 35 mm de compresión y 30 mm de extensión por rueda, independientes |
| Aire bajo una rueda sobre un badén fuerte | Hasta **6,5 mm** (la rueda quedaba en el aire) | Un escalón de 30 mm se reparte: izquierdas al tope de compresión, derechas al de extensión |
| Cabeceo y balanceo | **Prefijados a mano** en la malla del chasis, topados en ±2° | Del equilibrio de los cuatro muelles: medidos +0,126° acelerando, −0,305° frenando, 0,147–0,340° en curva |
| Vuelco con la carrocería | La rueda se inclinaba con el chasis | La rueda se mantiene alineada con el firme; solo se inclina con el peralte del asfalto |
| Fondo del neumático contra el asfalto parado | 0,1–4,9 mm (medición por caja) | **0,1 mm** (medición por punto más bajo real) |
| Garantía de no penetración | La pose rígida la daba por construcción | Verificada: plano del chasis + recorrido − asfalto medido = **−0,00 mm** |

### Capturas comparativas

El mismo coche en cuatro estados (parado, frenada, curva rápida y el resalto de prueba):
[rueda trasera izquierda](comparativa-rueda.png), [chasis desde atrás y abajo](comparativa-chasis.png)
y [la vista real del juego](comparativa-camara.png). Cada estado tiene además sus seis vistas
en [`vistas/`](vistas).

### La limitación de la fase 2, medida otra vez

Lo que la fase 2 dejó anotado —"sobre irregularidades fuertes, alguna rueda puede separarse
del suelo hasta 6,5 mm"— ya no ocurre: con recorrido por rueda, la rueda baja o sube hasta
encontrar el asfalto (hasta sus topes de 30/35 mm) y, cuando el badén los agota, sube el
chasis. En la prueba del resalto, un escalón de 30 mm se reparte entre las dos ruedas: las
izquierdas se comprimen hasta el tope y las derechas se extienden, sin que ninguna quede en
el aire ni atraviese el escalón.

## 6. El APK no llevaba el script (hallazgo de la corrida en el dispositivo)

Las diez pruebas de arriba son del **anfitrión**, y ahí `res://` es el árbol de trabajo:
Godot lee `scripts/wheel_suspension.gd` del disco y el archivo se carga aunque el preset de
exportación no lo declare. En el **teléfono** sólo existe lo que el APK empaqueta, y el
`include_filter` de [`export_presets.cfg`](export_presets.cfg) enumeraba seis scripts a mano
—los que había antes de esta fase—. El séptimo, el de la suspensión, **no viajaba**.

Lo encontró la primera corrida completa de `./verify.sh` de esta fase: las quince sondas del
anfitrión y las dos auditorías del circuito en verde y seis comprobaciones del dispositivo en
rojo (`registro_limpio`, `pantalla`, `lienzo`, `toque`, `cronometro`, `lienzo_final`), con el
listado en [`verify-fase3-antes-del-arreglo.log`](verify-fase3-antes-del-arreglo.log). La
causa está escrita en el registro del aparato, no deducida:

```
SCRIPT ERROR: Parse Error: Preload file "res://scripts/wheel_suspension.gd" does not exist.
   at: GDScript::reload (res://scripts/car_controller.gd:4)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/race.gd:0)
ERROR: Failed to load script "res://scripts/race.gd" with error "Compilation failed".
```

El `preload` del controlador no encuentra el archivo, el controlador no compila, la escena
no compila y el juego arranca mutilado (propiedades `model_root` y `lap_tracker` sin
asignar). De ahí caían `registro_limpio`, `lienzo`, `toque`, `cronometro` y `lienzo_final`:
no era la suspensión, era que **el APK entregado no era el juego que se había medido en el
anfitrión**.

Corrección, en dos partes:

1. `scripts/wheel_suspension.gd` entra en el `include_filter` del preset; el APK vuelve a
   llevar los siete scripts (`assets/scripts/wheel_suspension.gdc`, 7 190 bytes).
2. Comprobación nueva y **obligatoria** en [`verify.sh`](verify.sh) —`empaquetado`— con
   [`check_packaged.py`](.tools/recovery/check_packaged.py): lee el `include_filter`, calcula
   el nombre con el que Godot exporta cada archivo (`.gdc`, `.remap`, `.import`) y exige
   encontrarlo en el ZIP; después recorre los `res://` que **precargan** los scripts y las
   escenas empaquetadas y exige que viajen también. Sobre el APK corregido informa
   `empaquetado correcto: 174 archivos de res://`.

### La reproducción, para que el arreglo no se crea: se mide

Un arreglo sobre un archivo que ya no existe no se puede comprobar de memoria, así que el
fallo se reprodujo **a propósito y de nuevo en el dispositivo**, con el APK exportado desde
el preset recortado (exactamente el estado anterior al arreglo) firmado y instalado:
[`empaquetado-sin-script.log`](empaquetado-sin-script.log). Contiene las tres piezas:

1. La comprobación nueva, sobre ese APK: **falla** y nombra el problema por sus dos vías
   (falta en el preset **y** dependencia rota de `car_controller.gd`).
2. El logcat del arranque con ese APK: el mismo `Parse Error`, el `Compilation failed` de
   `race.gd` y las propiedades `model_root` / `lap_tracker` sin asignar.
3. El contraste, en el mismo dispositivo y la misma sesión: con el APK definitivo reinstalado
   hay **cero** líneas `SCRIPT ERROR`, y la huella del `base.apk` instalado coincide con la del
   APK en disco (`82837fac…`).

Un segundo control, más pequeño, deja claro que la herramienta no sólo mira el preset:
quitando `wheel_suspension.gdc` del ZIP pero dejándolo declarado, sigue fallando
([`empaquetado-negativo.log`](empaquetado-negativo.log)). El preset quedó restaurado byte a
byte tras la prueba.

### El dispositivo de medida

La batería está calibrada para un lienzo de **2400 × 1080** (`touch_controls.gd` y
`race_hud.gd` colocan los mandos para esa geometría, y `screen_check.py` compara contra
regiones absolutas). El AVD con el que empezó esta fase era otro —un Pixel 10, `F1`, de
1080 × 2424— y el juego dibuja 2424 de ancho: `pantalla` y `lienzo` fallaban por eso, no por
la suspensión. La corrida final se hace sobre un AVD de 1080 × 2400 (`Medium_Phone_3`,
densidad 420, GPU host), que es la geometría del dispositivo de aceptación documentado.

## 7. Fase 5 — regresión

* [`sonda_suspension`](sonda.log): `passed=true errores=0` (nueva, obligatoria).
* [`sonda_ruedas`](../fase2-ruedas/vistas) (la de la fase 2, sin cambios en sus criterios):
  pasa con cero errores. La geometría de las ruedas es la misma que se verificó entonces.
* `./verify.sh` completo, sobre el APK corregido y el emulador de 1080 × 2400:
  [registro de la corrida final](verify-fase3-final.log), [checks.tsv](../integral/checks.tsv),
  [resumen JSON](../integral/verificacion-integral.json) — **resultado: OK, 33
  comprobaciones, 0 fallos obligatorios, 0 omitidas**. Incluye las quince sondas del
  anfitrión (física, ruedas, **suspensión**, vuelta completa con aceleración, frenada,
  dirección, joystick y pedales, cámara, cronómetro y sectores, colisiones, escapatorias,
  movilidad fuera de pista y agarre por superficie), la auditoría del circuito y de los
  materiales entregados, la exportación del APK, su firma, la nueva auditoría de contenido
  `empaquetado`, la instalación, la huella del APK instalado, el arranque, la orientación y
  las barras del sistema, el lienzo sin bandas negras y las pruebas funcionales de toque en
  pantalla (gas, freno, mando, gas+dirección y freno+dirección simultáneos, cronómetro).
* APK definitivo de la fase: `build/android/F1OneShot-BarcelonaMoto.apk`,
  **247 675 489 bytes**, `sha256 82837facaeeab04374c3c9c533a3870ee10fcd884ed3b83b6c651b65ccc29e60`,
  exportado a las 16:38:21 e instalado sin incremental; el `base.apk` extraído del
  dispositivo tiene la misma SHA-256. Los 8 359 bytes que crece respecto al de la fase 2 son
  el script de la suspensión compilado (`wheel_suspension.gdc`, 7 190 bytes) y su remap.
* En el dispositivo, medido con este APK: arranque hasta el HUD en **28 s**, lienzo
  `2400×1080` en `ROTATION_90` con las dos barras del sistema ocultas, cero columnas negras,
  y las pruebas de toque en `PASS` (mando de `cx=185` a `303` y de vuelta a `195`).

## 8. Limitaciones pendientes (honestas)

1. **No es un coche de rayos completo.** El contacto real del vehículo sigue decidiéndolo la
   caja de colisión del `CharacterBody3D`; la suspensión resuelve la actitud del chasis y el
   recorrido de cada rueda a partir de un rayo por rueda. Un vehículo de fuerzas por rueda
   daría además reparto de frenada, bloqueo y pérdida de agarre por rueda descargada.
2. **La masa no es la fuente del reparto.** La distribución 46/54 la declara el proyecto; con
   un centro de gravedad en planta la transferencia saldría de la geometría. Se ha usado la
   declarada, que es la que usan el agarre y la carga aerodinámica del coche.
3. **Un solo rayo por rueda.** Un canto de bordillo dentro de la anchura del neumático (0,32
   m delante, 0,46 m detrás) no se ve: la rueda se coloca sobre la superficie que hay bajo su
   centro. En la sonda, 68 de las 3352 muestras se descartan por eso mismo.
4. **Ruedas rígidas en el sentido estructural**: no hay caída (camber) dinámica ni geometría
   de suspensión (brazos, manguetas). La rueda se traslada en vertical y se mantiene alineada
   con el firme.
5. **Sigue sin probarse en un teléfono físico**: emulador y host M1.
6. **Los fps son del host y varían por sesión**; no se ha medido coste de la suspensión con
   precisión —cuesta 4 rayos, un sistema 3×3 y un puñado de operaciones por fotograma— más
   allá de que la sonda y la vuelta completa se comportan igual que antes.

## 9. Cómo se reproduce

```bash
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --path . --script scripts/suspension_probe.gd   # las diez pruebas de la suspensión
$G --path . --script scripts/car_wheel_probe.gd    # geometría de las ruedas (fase 2)
./verify.sh                                        # verificación integral + APK
```

$G --headless --path . --export-debug Android build/android/F1OneShot-BarcelonaMoto.apk
python3 .tools/recovery/check_packaged.py build/android/F1OneShot-BarcelonaMoto.apk
```

Copia de recuperación del estado previo (fase 2): `estado-previo/` con el APK de la fase 2
y las instrucciones para volver atrás (`estado-previo/VOLVER-ATRAS.md`).
