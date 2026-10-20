# McLaren MP4/4 desde `AC2026/mclaren.7z` — coche y física con curvas del `data.acd`

**Fecha:** 20 de octubre de 2026
**Carpeta:** `.tools/recovery/mclaren-20261020/`
**Archivos tocados:** [`scripts/car_controller.gd`](../../../scripts/car_controller.gd), [`scripts/track_data.gd`](../../../scripts/track_data.gd)

## 1. Qué había y qué se pidió

El coche en juego ya era el R02 del archivo: se comprobó byte a byte antes de
tocar nada.

| Elemento | Archivo del 7z | En el juego | SHA-256 |
|---|---|---|---|
| Archivo completo | `AC2026/mclaren.7z` | — | `563c2ef3…d7c5c` (123 MiB) |
| Modelo | `vrc_1988_mclaren_mp4-4_r02_a.kn5` | [`MP44-Senna.glb`](../../../assets/MP44-Senna.glb) | `41eb7b58…5513` |
| Física | `vrc_1988_mclaren_mp4-4_r02/data.acd` | receta [`track_data.gd`](../../../scripts/track_data.gd#L340) | `ff09256f…9a62` |

El mod trae cuatro rondas (`r02`, `r04`, `r09`, `r10`), cada una con su propio
`data.acd` y su propio KN5; el juego usa la R02 con la librea `12_Senna_R02`,
que es la que se integró el 17 de octubre. Por eso no hubo que sustituir el
modelo: lo que faltaba era la física. La receta anterior reducía el coche a
**un punto de operación** (par de pico, carga a 100 m/s, tope de tracción fijo)
y no reproducía nada del comportamiento que depende del régimen, del turbo o de
la carga real del neumático. Eso es lo que se implementó.

## 2. Diseño: curvas opcionales en el controlador

`car_controller.gd` sigue siendo el mismo `CharacterBody3D`, pero ahora acepta
tablas por coche. Si una receta no las declara, el controlador usa el modelo
agrupado anterior **sin ningún cambio**, así que RB22 y Valkyrie quedan
intactos (comprobado: sus números de `ac_physics_probe` son idénticos a los del
informe de ayer).

| Campo de la receta | Origen en el mod | Uso en el controlador |
|---|---|---|
| `engine_torque_curve` | `power.lut` | Par base en el cigüeñal interpolado por régimen |
| `engine_boost_curve` + `engine_boost_count` | `turbo0.lut` / `turbo1.lut` | `T = T_base · (1 + Σ boost)`, con la curva de spool |
| `gears`, `final_drive_ratio`, `shift_rpm`, `downshift_rpm`, `idle_rpm` | `drivetrain.ini`, `engine.ini` | Régimen real `rpm = v/(2πr) · marcha · final · 60` |
| `clutch_launch_rpm` | `[AUTOCLUTCH] MAX_RPM=5000` | El embrague patina en la salida |
| `drivetrain_efficiency` | AC no lo declara | 1,0: AC aplica el par del cigüeñal a la rueda |
| `aero_downforce_n_at_100ms_off_throttle` | `aero.ini` + `ebd.lut` | CL·A a gas=0 (3,1825) frente a gas=1 (3,2825) |
| `front_tyre_grip_curve`, `rear_tyre_grip_curve` | `tyres.ini` `DY_CURVE` | Agarre frente a carga por rueda, normalizado en `FZ0` |

Fuerza en la rueda:

```
F = par(rpm, boost) · marcha · final · eficiencia / radio
F = min(F, max_engine_force_n)          # tope de agarre del eje trasero
F = F · pedal_limitado_por_agarre
```

El tope `max_engine_force_n = 7.200 N` se conserva porque el modelo no simula
deslizamiento de rueda: es el recorte de tracción, no el par bruto (1ª pide
13.062 N). El pedal sigue limitado por `_throttle_grip_limit`, que es lo que
hace que la punta no sea la de la potencia pura (ver limitaciones).

## 3. Tablas montadas (R02)

- **Par**: 31 puntos (0–15.000 rpm cada 500). Máximo **385,84 Nm a
  10.000 rpm**; **458,0 kW a 12.500 rpm** (99,96 Nm · 3,5).
- **Sobrepresión**: 27 puntos (0–13.000 rpm). Llega a 1,25 a 5.000 rpm y se
  mantiene; los dos turbos son idénticos y se suman.
- **Neumático**: 14 puntos por eje. Delante `FZ0 = 1.206,63 N`, detrás
  `1.809,95 N`, `DY0 = 1,5`. El agarre se aplana con la carga (µ 1,28 a
  3.000 N delante) en vez de caer como `1/√carga`: es lo que dice la tabla, y
  es la diferencia física más grande frente a la receta anterior.
- **Aero**: carga a 100 m/s de 20.105 N con el pedal a fondo y 19.493 N con el
  pedal suelto; CD·A = 1,1401 en los dos extremos (el EBD sólo mueve CL).
- **Caja**: 6 marchas (2,872 … 1,167) y final 4,1; subida a 12.500 rpm,
  bajada a 8.500 rpm, 220 ms de cambio.

Reproducible: [`derive_mclaren_curves.py`](derive_mclaren_curves.py) recalcula
las tablas desde la carpeta extraída del ACD y falla si la potencia o la carga
aero se apartan de lo auditado.

## 4. Comprobaciones

Registros en [`logs/`](logs/).

| Comprobación | Resultado |
|---|---|
| `--check-only` de `track_data.gd` y `car_controller.gd` | 0 |
| [`mclaren_curves_probe.gd`](mclaren_curves_probe.gd) | **0 fallos**: 31/27/14/14 puntos montados, par 211,16/385,84/349,86/332,50 Nm a 5.000/10.000/12.500/13.000 rpm, punta 284,9 km/h en 6ª |
| `ac_physics_probe` McLaren | **0 fallos**: 0–100 en 3,14 s, 0–200 en 6,97 s, 276,7 km/h en 15 s, 2,90 g de frenada, 1,16 g a 120 km/h y 2,08 g a 235 km/h |
| `ac_physics_probe` RB22 | **0 fallos**, valores idénticos a los de la receta anterior (2,99 s / 6,40 s / 318,7 km/h / 3,96 g / 1,32 g / 2,62 g) |
| `suspension_probe` McLaren | **passed=true, errores=0** |
| `selection_probe` (3 circuitos × 3 coches) | **PASS** en las 9 combinaciones |
| `understeer_probe` (RB22) | **0 fallos**, techos 1,10/1,42/1,91/2,53 g |
| `ac_physics_probe` Valkyrie (control de la vía agrupada) | 1 fallo **preexistente**: frenada 13,92 m/s² porque su receta declara 15.317 N de freno sobre 1.100 kg. No lo introduce este cambio (la ruta agrupada no se tocó) |

Cambios medidos frente a la receta anterior del McLaren: la frenada y el 0–100
no se mueven (siguen mandando el tope de tracción y el de freno), la punta a 15 s
baja de 280,0 a 276,7 km/h (ahora la fuerza sale del par real en 6ª y no de
`P/v`) y el agarre lateral a alta velocidad sube de 1,79 a 2,08 g porque la
curva `DY_CURVE` no penaliza la carga como la ley `1/√carga`.

## 5. Limitaciones

1. **Sin vuelta completa del McLaren.** `driving_probe` necesita ventana y
   foco; en esta sesión el coche se quedó a 36 km/h porque la ventana sin foco
   suelta los toques. No se declara como aprobado. Las comprobaciones en banco
   (aceleración, frenada, curva, suspensión) sí están hechas.
2. **Aero de altura fija.** Las tablas `FRONTGH`/`REARGH` se evalúan a 0,03 m
   delante y 0,04 m detrás; el controlador no simula altura de coche variable,
   así que no se reproduce el efecto suelo cambiante. El EBD sí está modelado.
3. **Sin temperatura ni desgaste de neumático.** `DY_CURVE` es la curva en
   frío/ideal del INI; no se aplican `PERFORMANCE_CURVE` ni presiones.
4. **Sin pérdidas de transmisión.** AC no las declara y se usa 1,0; si se
   quisieran modelar habría que bajar `drivetrain_efficiency`.
5. **El pedal limitado por agarre recorta la punta.** `_throttle_grip_limit`
   deja el pedal en ~0,83 en recta, así que la punta de equilibrio sale
   284,9 km/h en vez de los ~305 km/h que daría el motor con el pedal entero.
   Es un comportamiento anterior del controlador, no de las curvas, y no se
   tocó para no alterar RB22 ni Valkyrie.
6. **Turbos aditivos.** `T = T_base · (1 + Σ boost)` es la interpretación que
   reproduce los 458 kW del RA168E; AC no documenta aquí si se componen.
7. **No se reexportó el APK.** Sin ADB en esta sesión; los cambios son de
   scripts, así que hay que recompilar para probarlos en el dispositivo.
