# FASE: REDUCIR EL SUBVIRAJE DEL RED BULL SIN PERDER ESTABILIDAD

Sonda: `scripts/understeer_probe.gd` (nueva, añadida a `verify.sh` como comprobación
obligatoria `sonda_subviraje`).
Registros íntegros: `understeer-antes.log` y `understeer-despues.log` (esta carpeta).
Comparación limpia: **la MISMA sonda** aplicada a los dos estados del modelo. El «antes» se
mide revirtiendo sólo los tres parámetros del modelo que cambian (ver §3), con el resto del
árbol idéntico, así que la diferencia de los números es de la física y de nada más.

---

## 1. Causa raíz (medida, no supuesta)

El subviraje **no** venía del ángulo de dirección. La sonda mide, en cada velocidad y cada
recorrido del mando, cuál de los dos límites fija el tope:

```
BANCO 120 km/h mando=100% aplicado= 2,61° tope= 2,61° [lean 18,40° agarre 2,09°] fija=agarre
BANCO 240 km/h mando=100% aplicado= 0,85° tope= 0,85° [lean 12,08° agarre 0,68°] fija=agarre
BANCO  60 km/h mando=100% aplicado= 7,64° tope= 7,64° [lean 22,41° agarre 8,27°] fija=agarre
```

`lean` es lo que permite el manillar; `agarre` es el ángulo que satura la goma. **En las
cuatro velocidades el que manda es el agarre, y sobra carrera de mando por todas partes**
(a 120 km/h el manillar daba 18,4° y el coche sólo podía usar 2,61°). Es decir: descartado
que el problema fuera «falta de ángulo» (candidato A del encargo).

Tampoco era el reparto delantero/trasero (candidato C), aunque estuviera declarado al revés:
`front_grip_fraction = 0,47` daba al eje delantero 0,94 del coeficiente y al trasero 1,06.
Medido, ese reparto mueve menos del 1 % de la capacidad total (el modelo lateral es una
fuerza única sobre el cuerpo, no dos fuerzas de eje con su par), así que **se dejó neutro
(0,50) por coherencia, pero no era la causa**.

La causa es la **magnitud y la forma de la fuerza lateral disponible** (candidatos B y D):

| velocidad | capacidad antes | pedido por la tabla | defecto |
|---|---|---|---|
| 60 km/h | 1,03 g | 1,00 g | — |
| 120 km/h | **1,10 g** | 1,20 g | −8 % |
| 180 km/h | **1,21 g** | 1,70 g | −29 % |
| 240 km/h | **1,36 g** | 2,20 g | −38 % |

Con `aero_downforce_n_at_100ms = 7.100 N`, la carga aerodinámica a 250 km/h eran 1.775 N,
o sea **0,23 veces el peso**: casi nada. Por eso la capacidad crecía sólo **1,32 veces** de
60 a 240 km/h: era prácticamente un coche de agarre constante, y en curva rápida (donde la
física pide 1,7-2,2 g) el tren delantero se quedaba sin fuerza lateral y el coche se abría.
El efecto se ve en la trayectoria:

```
ANTES  CURVA rápida (vértice 215 m) a 222 km/h con el 70 % del mando:
       mando máximo necesario 100 %, mando topado el 100 % del tiempo,
       desvío hacia fuera 6,46 m, superficie OUT (fuera de pista)
ANTES  ESCENARIO entrada con acelerador a 113 km/h: desvío 9,55 m, superficie SAND
```

Y una segunda causa, en el control de tracción: `_throttle_grip_limit()` calculaba el agarre
que le queda al pedal con una **recta fija en g** (`0,58 − g·0,4`), no con la capacidad real
del coche. Con 1,04 g de curva dejaba el acelerador en el **41 %** aunque el coche tuviera
1,44 g de capacidad: el coche no salía de las curvas y el encargo pide expresamente
«acelerador y freno funcionales mientras se gira». No se ha desactivado ningún sistema: se
ha corregido con qué se compara.

Lo que **no** era: la curva del mando. La corrección de la fase anterior (exponente 1,6 → 0,90
más zona muerta) está intacta y medida: el 70 % del recorrido entrega 0,714 de demanda y el
tope de dirección se alcanza con el 80-85 % del recorrido (antes y después). El ángulo se
aplica entero (`aplicado = tope` a mando a fondo) y el margen de subviraje del modelo con el
mando a media carrera es **1,000** (el coche describe exactamente el radio que piden las
ruedas): no había ningún subviraje «escondido» en la cinemática, sólo falta de fuerza.

## 2. Criterio de aceptación

Tabla exigida a un monoplaza con carga aerodinámica (798 kg de masa). Es el criterio contra
el que se mide todo y **no sale de la medida del coche**:

| velocidad | capacidad exigida |
|---|---|
| 60 km/h | 1,00 g (el agarre mecánico de la goma ya está ahí: 1,03 g) |
| 120 km/h | 1,20 g |
| 180 km/h | 1,70 g |
| 240 km/h | 2,20 g |

Y el requisito del encargo «cerrar curvas sin necesitar el joystick al máximo» se mide en
km/h: **V70**, la velocidad a la que el coche describe el vértice de la curva con el 70 % del
recorrido del mando. El 70 % del recorrido entrega el 89,3 % de la capacidad (0,714 de
demanda × el 1,25 de ángulo extra que deja pedir el tope), así que para cumplir la tabla con
el 70 % del mando la capacidad del coche tiene que estar **un 12 % por encima de la tabla**.

## 3. Parámetros y archivos modificados

| archivo | qué | antes | después |
|---|---|---|---|
| `scripts/car_controller.gd` | `aero_downforce_n_at_100ms` | 7.100 N | **34.000 N** |
| `scripts/car_controller.gd` | `front_grip_fraction` | 0,47 (sesgo trasero) | **0,50 (neutro)** |
| `scripts/car_controller.gd` | `_throttle_grip_limit()` | recta fija en g | **círculo de adherencia contra la capacidad real** |
| `scripts/car_controller.gd` | `_top_speed_factor()` | se deducía de la carga aero | **declarado: 0,8975 (313 km/h, la punta medida)** |
| `scripts/understeer_probe.gd` | **nuevo**: la sonda de esta fase | — | — |
| `verify.sh` | nueva comprobación obligatoria `sonda_subviraje` | — | — |

34.000 N a 100 m/s son 16.400 N a 250 km/h = **2,09 veces el peso**, el extremo bajo del
rango real de la categoría (2,0-2,7), y es el valor que hace que la capacidad quede un 12 %
por encima de la tabla en todo el rango (que es lo que exige el criterio del 70 % del mando).
El agarre mecánico (a baja velocidad) **no se ha tocado**: a 60 km/h el coche sigue con
1,03 g antes y 1,11 g después, y se declara en la tabla una exigencia de 1,00 g precisamente
para no pedir un coche más agarrado de lo que es a baja velocidad.

La punta de velocidad no se mueve (el factor está declarado): sigue en 313 km/h.

No se ha tocado: la geometría del circuito, las colisiones, los materiales, las cámaras, la
curva del joystick, ni los sistemas de estabilidad (el control de tracción sigue ahí y sigue
recortando el pedal en el límite: con el coche al 100 % de su capacidad lateral el pedal se
queda en el 25 %).

## 4. Medidas antes / después

### 4.1 Capacidad lateral y respuesta con la velocidad

| medida | ANTES | DESPUÉS |
|---|---|---|
| techo 60 km/h | 1,03 g | **1,11 g** |
| techo 120 km/h | 1,10 g | **1,44 g** |
| techo 180 km/h | 1,21 g | **1,96 g** |
| techo 240 km/h | 1,36 g | **2,64 g** |
| ganancia 60 → 240 km/h | 1,32× (fuera del margen 1,35-3,40) | **2,37×** |
| reparto de ejes a 120 km/h | 0,48 del. + 0,62 tras. | 0,67 del. + 0,77 tras. |
| recorrido para el tope de dirección | 80-85 % | 70-85 % |
| margen de subviraje con el 70 % del mando | 1,000 | 1,000 |

### 4.2 Curvas reales de Barcelona (el vértice manda, no el radio medio)

| curva | vértice | velocidad exigida | V70 antes | V70 después | desvío hacia fuera antes | después | mando máx antes | después |
|---|---|---|---|---|---|---|---|---|
| lenta | 30 m | 58 km/h | 59 ✓ | **62** ✓ | 0,55 m | 0,55 m | 58 % | **53 %** |
| media | 94 m | 112 km/h | **107 ✗** | **129** ✓ | 0,52 m | 0,42 m | 80 % | **61 %** |
| rápida | 215 m | 222 km/h | **171 ✗** | **264** ✓ | **6,46 m ✗** (mando topado el 100 % del tiempo, fuera de pista) | **0,25 m** ✓ (mando topado el 0 %) | **100 %** | **69 %** |

La curva lenta apenas cambia: a esa velocidad manda la goma y ahí el coche ya estaba bien
(1,03 g de 1,00 exigidos). Donde cambia todo es a media y alta velocidad, que es donde estaba
la queja. El desvío se mide **con el mando topado al 70 % del recorrido**, así que mide
literalmente «¿cierra el coche la curva sin llevar el joystick al máximo?».

### 4.3 Escenarios de pedal (curva media, mando topado al 70 %)

| escenario | ANTES | DESPUÉS |
|---|---|---|
| entrada con acelerador | 113 → 124 km/h de salida, desvío 9,55 m, **SAND** | 113 → 122 km/h, desvío 2,51 m, asfalto |
| entrada soltando el acelerador | 46 km/h de media, 5 km/h al final | 46 km/h de media, 5 km/h (idéntico) |
| salida acelerando progresivo | 107 → 102 km/h | 115 → **120 km/h** |
| freno a mitad de curva | 83 → 74 km/h | 84 → 75 km/h |
| transición entre curvas opuestas (57 m / 56 m, 179 m) | desvío 0,00 m | desvío 0,00 m |

## 5. Comprobaciones: antes 8 fallos, después 0

```
ANTES    (8 fallos)                                  DESPUÉS (0 fallos)
- a 120 km/h sostiene 1,20 g (medido 1,10)           PASS 1,44 g
- a 180 km/h sostiene 1,70 g (medido 1,21)           PASS 1,96 g
- a 240 km/h sostiene 2,20 g (medido 1,36)           PASS 2,64 g
- la capacidad crece 1,32× (mínimo 1,35)             PASS 2,37×
- curva media: V70 107 < exigida 112                 PASS 129 ≥ 112
- curva rápida: V70 171 < exigida 222                PASS 264 ≥ 222
- curva rápida: se abre 6,46 m (tope 2 m)            PASS 0,25 m
- curva rápida: pico de mando 100 % (tope 85 %)      PASS 69 %
```

Y las que pasan en los dos estados, que son las que impiden «arreglar» el subviraje
rompiendo otra cosa: simetría izquierda/derecha a 120 km/h con el 100 % del mando (0 % de
diferencia), sin contacto con muro en el banco ni en las curvas, régimen regular sin oscilar
en el banco, sin derrape sostenido (deslizamiento lateral máximo 0,56 m/s en curva frente a
un tope de 3,0), sin trompo (0 instantes con el morro a más de 45° de la trazada), y la
transición entre curvas de sentidos opuestos cerrada con 0,00 m de desvío.

## 6. Validación final

1. `./verify.sh` completo → **ver §7**.
2. Pruebas de conducción: `sonda_subviraje` (esta fase) más las ya existentes
   (`sonda_conduccion` = vuelta completa, `sonda_mando`, `sonda_direccion`, `sonda_recto`,
   `sonda_replay`, `sonda_movilidad`, `sonda_impacto`, `sonda_suspension`, `sonda_ruedas`).
3. APK nuevo generado por la exportación del propio `verify.sh`.
4. Instalado y ejecutado en el emulador (sección 4 de `verify.sh`, con huella del instalado
   comparada con la del compilado).
5. Dirección con el joystick táctil real: comprobación `mando_dispositivo` (dedos reales
   sobre el anillo del mando, medido en pantalla).
6. Correcciones de colisiones y curva del joystick conservadas (no se han tocado).
7. Ruta, tamaño y SHA-256 del APK: **ver §7**.

## 7. Resultado de `verify.sh`

Corrida completa del 2026-10-16 00:37 (`checks-despues-20261016-0037.tsv`,
`verificacion-integral-despues-20261016-0037.json`): **54 comprobaciones, 51 ok, 3 fallo**, y
ninguna omitida (`SKIP_LONG=0`, la vuelta completa se condujo: `sonda_conduccion ok 539 s`).

La comprobación nueva de esta fase:

```
sonda_subviraje   ok   233 s   sonda scripts/understeer_probe.gd
SUBVIRAJE RESUMEN techo 60=1.11 g 120=1.44 g 180=1.96 g 240=2.64 g ganancia=2.37 fallos=0
```

Los tres fallos, uno por uno:

| comprobación | qué pasó | ¿es de este cambio? |
|---|---|---|
| `toque` | infraestructura ADB: `adb ... failed to get feature set: device offline` en los dos intentos de la comprobación (el servidor de adb lo comparten el emulador, el IDE y otras tareas en marcha) | **No.** Reejecutada la MISMA comprobación con el aparato en línea: `TOUCH PASS= True` (mando 185 → 303 → 195 px, gas 0,857, freno 0,871, evidencia en `toque-reejecucion-touch.json`) |
| `camara_pixeles` | «de 0 a 39 km/h el coche no crece (189 → 172 px)»: en la captura con el coche parado la silueta sale 189 px y en la de 39 km/h, 172 px | **No.** Falla igual, con los mismos números, en la corrida del build ANTERIOR (`checks-antes-build-20261015-2131.tsv`, entonces «0 a 41 km/h … 189 → 173 px») |
| `linea_dispositivo` | «la calzada del aparato sale azulada (dominante mediana 19,0 > 8,0 sobre 255)»: azul 19/255 en las capturas con el coche parado, y 8-9/255 con el coche en marcha, que es el valor del material corregido | **No.** Falla igual en la corrida del build anterior (mismo 19,0 en la misma captura): es un trozo de la goma de la trazada que quedó con el material viejo, y se ve cuando la cámara está parada, no por la física del coche |

Es decir: **ninguna regresión**. Las dos comprobaciones de píxeles ya venían fallando (el informe
del build anterior las declara fallidas con los mismos valores) y la de toque fue un corte del
servicio de adb, que al repetirse sobre el aparato en línea pasa.

Del resto de la corrida destacan, por lo que tocan a esta fase: `sonda_suspension ok`,
`sonda_ruedas ok`, `sonda_camara ok` y `audit_camara ok`, `sonda_morro ok` y `audit_morro ok`,
`sonda_movilidad ok`, `sonda_impacto ok`, `sonda_recto ok`, `sonda_replay ok`, `sonda_linea ok`
(y `sonda_conduccion ok`) — o sea, sin regresión en suspensión, ruedas, cámaras, colisiones ni
en la vuelta completa, que era el requisito de «sin regresiones» del encargo.

### APK entregado

| | |
|---|---|
| ruta | `build/android/F1OneShot-BarcelonaMoto.apk` |
| tamaño | 247.634.688 bytes (236 MiB) |
| SHA-256 | `4d54838276d98442a42249880f2652a1cf442336344e4afedb7e654f817523fa` |
| exportado | 2026-10-16 00:30:24 (por la propia corrida de `verify.sh`) |

- `firma ok` (apksigner verifica el APK), `empaquetado ok` (todo lo que el preset declara viaja
  dentro), `huella_apk ok`.
- `instalar ok` en `emulator-5556` y `huella_instalada ok`: **el SHA-256 del APK extraído del
  emulador coincide con el del compilado**, así que lo que se probó en el aparato es
  exactamente este APK.
- `arranque ok` y `registro_limpio ok` (el juego arranca, anuncia la pista y no deja errores
  en el registro).
- `mando_dispositivo ok` = **la dirección con el joystick táctil real medida en el aparato**:
  dedos de verdad sobre el anillo, con el coche girando en el sentido pedido y con capacidad
  de giro real a esa velocidad.
- `camara_dispositivo ok`, `morro_dispositivo ok`, `cronometro ok`, `lienzo ok` y
  `lienzo_final ok`: pantalla, HUD, cronómetro y cambio de vista intactos tras la corrección.

## 8. Observaciones y limitaciones

- **Frenada de motor muy fuerte**: soltando el acelerador a 113 km/h el coche baja a 5 km/h en
  unos 100 m. Se ha medido **idéntico antes y después**, así que no viene de esta corrección;
  no es subviraje y no se ha tocado, pero queda anotado para una fase propia.
- **La línea de asistencia no se ha tocado**: sus velocidades ideales (60/109/171 km/h en las
  tres curvas) se calcularon con la capacidad vieja del coche, así que ahora son más
  conservadoras de lo necesario. Es correcto que lo sean (una ayuda no debe pedir el límite),
  pero conviene decidir en otra fase si se recalcula.
- No probado en teléfono físico: las comprobaciones de dispositivo son sobre el emulador.
- El desvío en la curva lenta y en la transición no distingue este cambio (a baja velocidad el
  agarre mecánico manda y no se ha tocado): son comprobaciones de no-regresión.
