# LM Hypercar Valkyrie — integración, físicas propias y APK

Fecha: 20 de octubre de 2026
Vehículo: LM Hypercar Valkyrie · 007 (`AC2026/valk/`)
Entrega: `build/android/F1OneShot-Valkyrie-20261020.apk`

## 1. Qué se entrega

El Valkyrie es un vehículo más del juego, no una skin ni una demostración:

* **Menú principal**: botón propio «LM HYPERCAR / VALKYRIE · 007» en la fila de
  vehículos, junto a McLaren y Red Bull, y recuadro 3D con el modelo real
  (`assets/Valkyrie-LMHypercar.glb`, 52 mesh / 225 primitivas / 85 texturas
  embebidas) girando en la vista previa.
* **Física propia**: al elegir el Valkyrie, `race.gd` aplica el bloque `physics`
  de `valkyrie` en `scripts/track_data.gd`. Nada de ese bloque se comparte con
  el RB22 ni con el MP4/4: masa, batalla, reparto, potencia, carga
  aerodinámica, arrastre, frenos, neumático, muelles, amortiguadores, caja y
  reparto de agarre son valores propios.
* **Controles táctiles**: las 60 comprobaciones de la sonda de dirección
  (acelerar, frenar, 25/50/100 % de recorrido, izquierda y derecha, 60–240 km/h)
  pasan con el Valkyrie sin fallos.

## 2. Origen de los números

Todos salen de `AC2026/valk/data.acd` (recuperado con `acd.py` 1.1.0; informe
previo en `.tools/recovery/valk-acd-viability-20261019/`) y están comentados en
`track_data.gd` junto al valor de origen:

| Magnitud | Valor usado | Origen |
|---|---|---|
| Masa | 1100 kg | `car.ini` `TOTALMASS` |
| Batalla declarada | 2,922 m | `suspensions.ini` `WHEELBASE` |
| Altura del CG | 0,43 m | `suspensions.ini` (radio + altura de buje, media de ejes) |
| Reparto delantero | 0,48 | `suspensions.ini` `CG_LOCATION` |
| Potencia | 368,6 kW | `engine.ini` + `power.lut` (419 Nm @ 8400 rpm, corte) |
| Fuerza de tracción | 12 340 N | 466 Nm × 2,90 × 3,10 / 0,3395 m |
| Fuerza de frenada | 15 317 N | 5200 Nm / 0,3395 m |
| Radio de rueda | 0,3395 m | `tyres.ini` `RADIUS` |
| Carga aerodinámica | 19 935 N a 100 m/s | `aero.ini` + LUTs, CL 1,972, S 1,6504 m² |
| Arrastre | 0,627 m² | CD 0,3798 × S |
| Muelles | 80 / 70 kN/m | `suspensions.ini` |
| Sensibilidad a la carga | 0,1105 | `tyres.ini` `LS_EXPY` 0,8895 |

La velocidad punta se fija con `max_forward_speed_ms = 97` y
`top_speed_factor = 1,0` (349 km/h), coherente con un LMH y por debajo del
tope del RB22 (`0,8975 × 97` = 313 km/h).

## 3. Cambios de esta sesión

1. `scripts/suspension_probe.gd`
   * La sonda medía `wheel.mesh`: en el RB22 y el McLaren la rueda es una sola
     `MeshInstance3D`, pero en el Valkyrie es un pivote que agrupa llanta, disco
     y neumático. Ahora `_wheel_box()` une las cajas de todas las mallas hijas en
     el espacio de la rueda (misma medida para los tres coches).
   * `car.suspension.front_weight` no existe; la propiedad es
     `front_weight_fraction`.
2. `scripts/race.gd`
   * `_adapt_valkyrie_wheels()` recentra el pivote sobre la caja del grupo
     cuando no está centrado. El `WHEEL_RR` del modelo venía 33,86 mm por fuera
     del centro del neumático: al girar, la rueda describía una órbita de
     10,39 mm y la vía trasera quedaba descuadrada (0,8047 / −0,7703 m). Ahora
     0,7700 / −0,7703 m, pivote a 0,04 mm y órbita a 0,05 mm, sin mover ni un
     vértice de lo que se ve.
3. `scripts/car_controller.gd`
   * `launch_throttle_factor` (por defecto 0,62, el valor que ya tenía) sustituye
     la constante del recorte de acelerador por velocidad. El recorte se calibró
     para el F1; un LMH de 1100 kg con 12 340 N de tope de tracción se quedaba en
     88 km/h a los 3,5 s de plena carga. El valor por defecto no cambia el RB22
     ni el McLaren (medido: idénticos antes y después).
4. `scripts/track_data.gd`
   * `launch_throttle_factor: 0.95` en el bloque del Valkyrie (su salida está
     limitada por el motor, no por un recorte de pedal).
5. `export_presets.cfg`
   * **El APK no llevaba el Valkyrie**: `include_filter` está vacío y
     `export_files` enumeraba 180 archivos sin el GLB. Se añadieron
     `res://assets/Valkyrie-LMHypercar.glb` y
     `res://assets/Valkyrie-LMHypercar_mirror.png` (la única textura externa que
     referencia el `.scn` importado; las otras 84 van embebidas en el GLB). Sin
     esto el juego en el teléfono habría arrancado sin el coche.

## 4. Verificación (host, Godot 4.7.2 headless)

| Prueba | Resultado | Registro |
|---|---|---|
| `selection_probe` | 9/9 combinaciones PASS + menú con modelo real | `logs/selection-probe.log` |
| `suspension_probe rb22_2026` | `passed=true errores=0` | `logs/suspension-probe-rb22_2026.log` |
| `suspension_probe mclaren` | `passed=true errores=0` | `logs/suspension-probe-mclaren.log` |
| `suspension_probe valkyrie` | `passed=true errores=0` | `logs/suspension-probe-valkyrie.log` |
| `track_regression` Barcelona | `failures=0`, contacto 4, goma a ≤ 14,6 mm | `logs/track-barcelona-valkyrie.log` |
| `track_regression` Suzuka | `failures=0`, goma a ≤ 1,4 mm | `logs/track-suzuka-valkyrie.log` |
| `track_regression` Montreal | `failures=0`, goma a ≤ 0,6 mm | `logs/track-montreal-valkyrie.log` |
| `steering_response_probe` (táctil) | 60 comprobaciones, 0 fallos | `logs/touch-valkyrie.log` |
| `probe_compare` (3 coches) | RB22 y McLaren idénticos antes/después | `logs/compare-all-3.log` |
| `check_packaged.py` | 182 declarados, 1152 archivos de `res://`, 0 dependencias rotas | `logs/android-export.log` |
| `apksigner verify --print-certs` | firma válida, CN=Godot | `logs/android-export.log` |

Medidas del Valkyrie frente a los otros dos (misma escena, mismo circuito):

```
                 masa  batalla  vía del/tras   0-100    lateral 100 km/h  radio
rb22_2026         798   3,403   1,550/1,472   ~1,9 s        1,27 g       69,6 m
mclaren           798   2,874   1,816/1,670   ~1,9 s        1,27 g       69,6 m
valkyrie         1100   3,186   1,592/1,540   ~3,0 s        1,09 g       76,7 m
```

En recta a fondo desde parado (muestras cada segundo): RB22 41/85/132/178/215
km/h; Valkyrie 34/66/98/128/151 km/h. La diferencia es la que declara la ficha
(peso, potencia y carga aerodinámica propios), no un fallo de carga.

## 5. APK

* Ruta: `build/android/F1OneShot-Valkyrie-20261020.apk`
* Tamaño: 1 370 254 988 bytes (1,37 GB)
* SHA-256: `f3bfd259ebd6d8ba4aa34efd0b5c67c0bcfe2a914fb8d8f05aff2a90744535a2`
* Firma: `CN=Godot, OU=Godot Engine, O=Stichting Godot, C=NL`,
  SHA-256 `16add3e871c8f5960e1876fb20ff0cce444915a880d8c9b509f1095e5dddc4ff`
* Contenido relevante:
  * `assets/.godot/imported/Valkyrie-LMHypercar.glb-4c73….scn` (31,9 MB)
  * `assets/assets/Valkyrie-LMHypercar.glb.import`
  * `assets/.godot/imported/Valkyrie-LMHypercar_mirror.png-4df8….ctex`
  * `assets/scripts/{race,car_controller,track_data,main_menu}.gdc` del día

## 6. Límites, dichos sin adornos

* El controlador **no reproduce** la simulación de Assetto Corsa. Es un
  `CharacterBody3D` con integración manual y guiñada cinemática: la suspensión,
  el agarre, la caja y la aerodinámica son modelos de 12–20 parámetros
  calibrados con los datos del `.acd`, no las Ecuaciones del motor original. No
  hay ERS, ni control de tracción por rueda, ni curva de embrague, ni el
  diferencial del coche.
* La batalla efectiva es la **medida en el modelo** (3,186 m), no la declarada
  (2,922 m): manda la geometría real de los pivotes para que las ruedas pisen
  donde se ven.
* La salida desde parado sigue pasando por un modelo de pedal compartido; con
  el factor propio del Valkyrie da 0–100 en ~3,0 s, cifra razonable para un LMH
  pero no una medida homologada.
* **No se ha instalado en un teléfono ni en un emulador**: no había dispositivo
  ADB conectado (`cannot connect to daemon at tcp:5037`). La firma, el contenido
  y la ausencia de dependencias rotas están comprobados sobre el APK; el
  arranque en dispositivo queda pendiente.
