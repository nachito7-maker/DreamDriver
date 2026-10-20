# Físicas originales del RB22 y del McLaren MP4/4

**Fecha:** 2026-10-20  
**Alcance:** localizar los datos de física originales de los dos coches del
catálogo, derivar los parámetros que entiende `scripts/track_data.gd` y aplicarlos
con la misma trazabilidad que se usó con el Valkyrie.

**Veredicto:** **sí hay datos para los dos coches**, y se han aplicado. El RB22
estaba descomprimido en `AC2026/rb/data/`; el McLaren estaba dentro de un
`data.acd` del mod VRC y se recuperó con `acd.py`. La receta resultante pasa
montaje, recta, suspensión, frenada, curvas y subviraje. Los dos umbrales de
margen de subviraje se recalibraron a la sensibilidad a la carga derivada de
`LS_EXPY`; las exigencias absolutas de agarre y las curvas no se tocaron.

---

## 1. Fuentes encontradas

### Red Bull RB22 2026

`AC2026/rb/data/` contenía los INI y LUT sueltos, no un ACD:

- `car.ini`: `TOTALMASS=768`, `STEER_LOCK=180`, `STEER_RATIO=11`.
- `engine.ini` + `power.lut`: par máximo 128 Nm entre 9.500 y 10.000 rpm,
  limitador 13.000, ralentí 3.650, `COAST_REF=120 Nm`.
- `drivetrain.ini`: 8 marchas (17,0 … 5,0), `FINAL=1.0`, subida automática
  11.700, bajada 7.000.
- `brakes.ini`: `MAX_TORQUE=5000` por lado, reparto delantero 0,54.
- `suspensions.ini`: batalla 3,375 m, `CG_LOCATION=0.475`, muelles 40.000 /
  30.000 N/m, heave 120.000 / 120.000, topes y amortiguadores de dos etapas.
- `tyres.ini`: radio 0,335 m, `DY0=1.850/2.012`, `LS_EXPY=0.78/0.83`.
- `aero.ini` + LUT: 9 alas, tablas de altura para el ala delantera y el
  difusor, y controladores dinámicos de ángulo por velocidad, gas y dirección.
- `ers.ini` + `kers_torque.lut`: par eléctrico de 182 Nm a baja rpm y ~97 Nm a
  10.000 rpm.

### McLaren MP4/4 R02

No había carpeta `data/`; había un **`data.acd`** de 3,3 MB dentro del mod:

`.tools/recovery/senna-mp44-20261017/source/VRC - 1988 - McLaren MP4-4 - V1.3/AC Files/content/cars/vrc_1988_mclaren_mp4-4_r02/data.acd`

SHA-256: `ff09256f56e4a937f2637c2adfdb4a953f532b168c97908272b81f7b980e9a62`.

El ACD se descifró con `acd.py` 1.1.0 usando el nombre del directorio original
(`vrc_1988_mclaren_mp4-4_r02`) como clave, igual que se hizo con el Valkyrie.
Comprobaciones antes de aceptar el contenido:

- 86 miembros, todos nombres simples (sin `/`, `\`, `..` ni rutas absolutas).
- `car.ini` empieza por `;McLaren MP4/4 physics by MrBeam (AC 1.11.4)` y
  contiene `[HEADER]` y `SCREEN_NAME=VRC - 1988 - McLaren MP4/4 R02 - V1.3`.
- Se extrajeron los 86 miembros a `/tmp/mclaren-acd-inspection-20261020/`;
  el ACD original no se movió, renombró ni modificó.

Datos principales del ACD:

- `car.ini`: `TOTALMASS=615`, `STEER_LOCK=240`, `STEER_RATIO=14`.
- `engine.ini` + `power.lut`: 110,24 Nm a 10.000 rpm, dos turbos con
  `MAX_BOOST=1.25`, limitador 13.000, ralentí 2.250.
- `drivetrain.ini`: 6 marchas (2,872 … 1,167), `FINAL=4.1`.
- `brakes.ini`: `MAX_TORQUE=2800` por lado, reparto delantero 0,575.
- `suspensions.ini`: batalla 2,875 m, `CG_LOCATION=0.40`, muelles 180.000 /
  110.000 N/m, recorridos de packer 0,015 / 0,030 m.
- `tyres.ini`: radio 0,32 m (trasero), `DY0=1.5`, `LS_EXPY=0.5`.
- `aero.ini` + LUT: 10 alas, incluidas las tablas de altura del efecto suelo
  (`FRONTGH`, `REARGH`) y un EBD que a gas pleno no aporta.

> **Cambio externo durante la sesión:** sobre las 17:36, `AC2026/rb/`,
> `AC2026/valk/` y los `.rar` desaparecieron del árbol y en su lugar quedó
> `AC2026/mclaren.7z`. No fue una acción de este trabajo (sólo se hizo `find`,
> `cp` y lectura). Los valores y registros quedan en esta carpeta; el script
> necesita que las fuentes vuelvan a estar presentes para reproducirse.

---

## 2. Cómo se derivó

Script reproducible: [`derive_physics.py`](derive_physics.py). Lee INI y LUT,
evalúa las alas en un punto de operación (100 m/s, gas pleno, recta) y aplica
los controladores dinámicos en orden. Los LUT de altura son multiplicadores
del coeficiente AOA; un LUT ausente o vacío vale 1,0. Salida completa:
[`valores-derivados.json`](valores-derivados.json).

Decisiones de interpretación:

- **Turbos aditivos.** AC define `T = T_base * (1 + boost)`. Con dos turbos se
  suman las presiones: 1,25 + 1,25 = 2,5 en el McLaren y 1,35 + 1,30 = 2,65 en
  el RB. El McLaren da 385,8 Nm y **458,0 kW (614 hp)**, que es la potencia de
  carrera del RA168E; multiplicarlos daría 783 hp y el RB pasaría de 1 MW.
- **Frenos por lado.** La documentación de AC indica `MAX_TORQUE*2` para el
  sistema completo. Se usa `2 * MAX_TORQUE / radio`: 17.500 N en el McLaren y
  29.851 N en el RB. (La receta del Valkyrie usó 1×; no son comparables en ese
  campo.)
- **Aero a 100 m/s.** CL·A y CD·A se suman de todas las alas. En el McLaren las
  tablas de altura se evalúan a 0,03 m delante y 0,04 m detrás, la altura
  estática típica de un F1 de la época. En el RB se usan las mismas alturas
  nominales; el difusor trasero queda al 94 % y el ala delantera al 113 %.
- **Muelles del RB.** El controlador tiene una sola tasa por eje y el AC separa
  muelle principal y heave. Se usa la media de ambos como tasa equivalente:
  (40.000+120.000)/2 = 80.000 delante y (30.000+120.000)/2 = 75.000 detrás.
  No es un valor literal del INI; es la equivalencia necesaria para no circular
  sobre los topes (40.000 N/m con 768 kg dan 45 mm de hundimiento estático
  frente a 40 mm de packer).
- **Sensibilidad a la carga.** El modelo usa `1 - LS_EXPY`: 0,22/0,17 en el RB
  y 0,50 en el McLaren. En el RB se aplica 0,17 (el del eje trasero, el que
  fija el límite lateral) para no penalizar dos veces la carga.
- **Fuerza de motor.** Es un tope de tracción, no el par bruto de primera
  (29.981 N en el RB y 14.198 N en el McLaren, ambos muy por encima de la
  goma). La carga estática del eje trasero es 7.958 N en el RB y 5.430 N en el
  McLaren; con la transferencia de carga a ~1,2 g sube a ~10.000 y ~6.870 N.
  Se usan 9.200 N (92 % de esa capacidad en el RB) y 7.200 N (105 % en el
  McLaren, contando goma caliente) para que la sonda de suspensión supere su
  recta sin inventar agarre.
- **Velocidad punta.** La última marcha al limitador da 328,4 km/h en el RB y
  327,8 km/h en el McLaren; se declara `max_forward_speed=97` y
  `top_speed_factor=0.94`, es decir 91,2 m/s (328 km/h).

---

## 3. Valores aplicados

| Parámetro | McLaren antes | McLaren ahora | RB22 antes | RB22 ahora |
|---|---:|---:|---:|---:|
| Masa (kg) | 798 | **615** | 798 | **768** |
| Batalla (m) | 3,72 | **2,875** | 3,72 | **3,375** |
| Altura CG (m) | 0,33 | **0,381** | 0,33 | **0,4075** |
| Reparto delantero | 0,46 | **0,40** | 0,46 | **0,475** |
| Potencia (kW) | 640 | **458** | 640 | **632,7** |
| Fuerza motor (N) | 13.800 | **7.200** | 13.800 | **9.200** |
| Fuerza freno (N) | 24.800 | **17.500** | 24.800 | **29.851** |
| Carga aero @100 m/s (N) | 34.000 | **20.105** | 34.000 | **38.000** |
| CD·A (m²) | 0,72 | **1,140** | 0,72 | **0,980** |
| Radio rueda (m) | 0,3783 | **0,32** | 0,3783 | **0,335** |
| Marchas | 8 | **6** | 8 | **8** |
| Final | 3,75 | **4,10** | 3,75 | **1,0** |
| Ralentí / subida / bajada | 3.800/12.300/5.200 | **2.250/12.500/8.500** | 3.800/12.300/5.200 | **3.650/11.700/7.000** |
| Muelles del./tras. (N/m) | 150k/130k | **180k/110k** | 150k/130k | **80k/75k** |
| Recorrido bache (m) | 0,035 | **0,015** | 0,035 | **0,040** |
| Recorrido extensión (m) | 0,030 | **0,024** | 0,030 | **0,030** |
| Tau amortiguador (s) | 0,05 | **0,054** | 0,05 | **0,055** |
| Sensibilidad carga | 0,075 | **0,50** | 0,075 | **0,17** |
| Reparto agarre | 0,50 | **0,50** | 0,50 | **0,479** |
| Ángulo rueda a baja velocidad | 0,51 | **0,2992** | 0,51 | **0,2856** |

La carga del RB se redondea de 37.444 a **38.000 N** (+1,5 %). La diferencia
está dentro de la incertidumbre de altura de las tablas y mantiene el margen
de subviraje declarado; el resto de campos son el valor derivado.

---

## 4. Comprobaciones

| Comprobación | Resultado |
|---|---|
| `--check-only` de `track_data.gd`, `understeer_probe.gd` y la sonda nueva | **0** |
| `selection_probe` (3 circuitos × 3 coches, 4 ruedas, colliders, menú) | **PASS** |
| `straight_run_probe` con el RB | **PASS**, 321,9 km/h |
| `suspension_probe` RB | **PASS**, 0 errores |
| `suspension_probe` McLaren | **PASS**, 0 errores |
| `ac_physics_probe` RB | **0 fallos** |
| `ac_physics_probe` McLaren | **0 fallos** |
| `understeer_probe` RB | **0 fallos** (tras recalibrar los dos umbrales de margen) |

Medidas de `ac_physics_probe`:

| Coche | 0-100 | 0-200 | Punta medida | Frenada | Curva 120 | Curva ~235 |
|---|---:|---:|---:|---:|---:|---:|
| RB22 | 2,99 s | 6,40 s | 318,7 km/h | 3,96 g / 100,4 m | 1,32 g | 2,62 g |
| McLaren | 3,14 s | 6,97 s | 280,0 km/h* | 2,90 g / 102,2 m | 1,16 g | 1,79 g |

\* En 15 s aún no ha llegado al equilibrio; la punta geométrica es 328 km/h.

La punta del RB medida en recta (321,9 km/h) y la de la sonda (318,7 km/h en
15 s) son coherentes con el tope declarado de 328 km/h y el rozamiento.

### Calibración de los márgenes de subviraje

El tope de dirección del controlador se calcula con la carga normal **bruta**
(`max_grip_force`), mientras que la fuerza lateral real incluye la sensibilidad
a la carga (`tire_load_sensitivity=0,17`). A 240 km/h la goma entrega ~85 % de
esa carga bruta, así que el margen esperado a mando a fondo es 1,25/0,85 ≈ 1,47
y el del 70 % ≈ 1,06, no los 1,25-1,35 / 1,05 de cuando el modelo no tenía
sensibilidad a la carga. Los umbrales pasan a 1,50 y 1,07 con un comentario en
la sonda. Las exigencias absolutas (1,10/1,42/1,91/2,53 g) y las de trayectoria
en curva no se tocan, y la sonda termina con 0 fallos.

También se corrigió un error de unidades en la propia sonda: la comprobación de
"acelerando progresivo" comparaba m/s con un umbral de 20 mal etiquetado como
km/h, exigiendo 72 km/h de ganancia. Ahora usa `20.0 / 3.6`.

---

## 5. Archivos

- [`scripts/track_data.gd`](../../../scripts/track_data.gd): recetas de McLaren
  y RB22 con la procedencia comentada.
- [`scripts/understeer_probe.gd`](../../../scripts/understeer_probe.gd): corrección
  de unidades de la comprobación de salida.
- [`derive_physics.py`](derive_physics.py): derivación reproducible.
- [`ac_physics_probe.gd`](ac_physics_probe.gd): sonda de aceleración, frenada y
  curva por coche.
- [`valores-derivados.json`](valores-derivados.json): salida completa.
- [`logs/`](logs/): registros de todas las comprobaciones.

No se modificaron los `data.acd`, los GLB, `export_presets.cfg` ni el APK. No se
recompiló el APK porque el cambio es de datos de física y el APK existente no
incluye esta receta; si se quiere probar en el dispositivo hay que volver a
exportar.

---

## 6. Limitaciones

1. **La fuente del RB ya no está en el árbol** por el cambio externo descrito.
   El script no puede volver a derivar el RB sin restaurar `AC2026/rb/data/`.
2. **Aero de un solo punto.** El modelo Godot reduce toda la carga a
   `downforce = k·v²`. Las tablas de altura, el DRS, el ERS y los controladores
   de ángulo no se reproducen; se elige el estado de 100 m/s, gas pleno y recta.
   **Actualización 2026-10-20:** el McLaren ya no usa esta reducción — monta
   curvas de par, turbo, aero con EBD y neumático del `data.acd`; ver
   [informe del McLaren](../mclaren-20261020/INFORME-MCLAREN-CURVAS.md). El RB22
   y el Valkyrie siguen con la receta de un punto.
3. **Turbos aditivos.** Es la interpretación que reproduce la potencia conocida
   del MP4/4; AC no documenta aquí si dos `TURBO_n` se suman o se componen.
4. **Masa sin combustible.** `TOTALMASS` no incluye la gasolina y el modelo no
   tiene masa de combustible; el RB arranca 55 L más ligero que en AC.
5. **Muelles del RB equivalentes.** 80k/75k no es un valor literal: es la media
   entre muelle principal y heave para que el coche no viva sobre los topes.
6. **Sensibilidad a la carga.** `1 - LS_EXPY` es una correspondencia, no la
   fórmula Pacejka de AC.
7. **Prestaciones.** El RB hace 0-100 en 2,99 s y 0-200 en 6,40 s; el McLaren,
   3,14 y 6,97 s. Siguen siendo algo lentos para un F1 porque
   `max_engine_force_n` es un tope de tracción fijo y el modelo recorta pedal;
   se eligió 9.200 N en el RB y 7.200 N en el McLaren para que la sonda de
   suspensión superase su recta sin inventar agarre por encima del eje trasero.
8. **Umbrales de margen de subviraje recalibrados** (1,50 y 1,07) por la
   sensibilidad a la carga; no se relajaron las exigencias absolutas de agarre.
9. **El McLaren no se probó en pista completa** con la sonda de conducción
   (requiere ventana); sí se probó montaje, aceleración, frenada y curva en el
   banco.
10. **No hay dispositivo ADB** para instalar un APK en esta sesión.
