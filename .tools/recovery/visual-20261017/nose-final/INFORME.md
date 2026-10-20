# Cámara de morro, definición del monoplaza y APK — cierre del 17/10/2026

## 1. Qué se ha corregido

**Cámara de morro (el problema principal).** El punto de vista estaba a 1,25 m
detrás del eje delantero y sólo 0,25 m por encima del alto del neumático
(1,001 m sobre el suelo): los neumáticos quedaban a 1,6 m de la lente y llenaban
las esquinas inferiores con deformación de gran angular (5,54 % y 4,74 % del
lienzo cada uno en la comparación a la misma pose; 5,5 % y 3,8 % en la pasada de
la sonda a 150 km/h; borde superior en el 60 % del alto). Se ha reanclado sobre
el cockpit, como una T-cam:

| parámetro | antes | ahora |
|---|---|---|
| detrás del eje delantero | 1,25 m | **1,70 m** |
| sobre el alto del neumático | 0,25 m | **0,45 m** |
| inclinación hacia abajo | 4,0° | 4,0° |
| campo de visión vertical | 61,0° | **62,0°** |

Punto de vista resultante, medido del modelo: `(0.000, 1.201, 0.189)` en el
marco del coche. Los neumáticos bajan a 2,4 m de la lente y pasan a ocupar
3,2 % y 2,8 % del lienzo, con el borde superior en el 65–67 % del alto. La
pista domina el centro, el horizonte queda en el 44 % del alto, el morro con la
librea y el halo siguen en la franja inferior y el casco/cockpit asoma abajo.

**Capturas de la sonda de morro.** La sonda leía fotogramas congelados en macOS
cuando la ventana quedaba tapada: en la primera pasada las cinco capturas de un
caso salieron con **el mismo SHA-256** y la auditoría en píxeles dio cero
neumático. Se añadió a `_shot()` la comprobación de que la captura CAMBIA
respecto al fotograma del que tiene que diferir, con reintento tras traer la
ventana al frente y forzar el dibujado; si aun así no cambia, la sonda lo
declara como error en vez de medir una foto vieja. Es un arreglo del
instrumento, no de los criterios: las reglas de composición no se han tocado.

**Giro visual de las ruedas.** Se conserva el tope de 36 rad/s del fotograma
anterior (`car_controller.gd`). Medido sobre las cuatro ruedas montadas
(`.tools/work/wheel_spin_measure.gd`, ángulo que avanza la base de cada rueda
entre dos `_update_visuals`):

| velocidad | 1/60 s | 1/30 s | giro físico |
|---|---|---|---|
| 30 km/h | 0,367 rad (21°) | 0,734 rad (42°) | 22,0 rad/s (sin tope) |
| 60 km/h | 0,600 rad (34,4°) | 1,200 rad (68,8°) | 44,1 rad/s (topado) |
| 150 km/h | 0,600 rad (34,4°) | 1,200 rad (68,8°) | 110,1 rad/s (topado) |
| 330 km/h | 0,600 rad (34,4°) | 1,200 rad (68,8°) | 242,3 rad/s (topado) |

El giro físico se conserva intacto hasta ~49 km/h y a partir de ahí el tope deja
0,60 rad por fotograma a 60 FPS (0,096 vueltas), por debajo de medio paso entre
radios. En el aparato, a 46–49 FPS medidos, el tope da 0,73–0,78 rad por
fotograma (44°). No se ha subido el límite.

**Definición del monoplaza.** Se mantiene el ajuste de material del cuerpo
(metallic 0,20 / roughness 0,40 / clearcoat 0,12) y `scaling_3d/scale=1.12`.
Comprobado que el escalado 3D **sí se aplica** en GL Compatibility: la misma
escena renderizada a escala 1,0, 1,12 y 0,5 da imágenes distintas (comparación
por igualdad de bytes), y el gradiente medio en la banda del coche baja de
8,52 a 7,51 al subir a 1,12, que es lo que hace el supermuestreo (menos
escalones, no más contraste).

## 2. Archivos modificados

- `scripts/race.gd`: exports de la cámara de morro (`nose_behind_axle_m` 1,70,
  `nose_above_wheels_m` 0,45, `nose_fov` 62,0) y sus comentarios.
- `scripts/camera_nose_probe.gd`: detección de capturas congeladas con
  reintento (`_shot(nombre, distinto_de)` y `_misma_imagen`).
- Nuevos, sólo de instrumentación: `.tools/work/nose_candidates.gd`,
  `.tools/work/body_material_shots.gd`, `.tools/work/scaling_check.gd`,
  `.tools/recovery/visual-20261017/nose-final/validar_morro_dispositivo.py`.

No se ha tocado `wheel_suspension.gd`, ni la física, ni la dirección, ni el
motor, ni la transmisión, ni los controles táctiles, ni la geometría del
circuito, ni la cámara exterior.

## 3. Resultado de las sondas (host)

| sonda | resultado |
|---|---|
| `camera_nose_probe.gd` | **passed=true**, 6 casos, 2 transiciones, 0 errores. Holgura con el carenado 0,381 m; horizonte 0,44; pista por delante 5/5; deriva de cámara 0,0000 m; paso máximo 0,0001 m. Cambio de vista: holgura mínima 0,231 m, cronómetro monótono 15,91→16,48 s, vueltas 0→0, avance 25,5 m a 160,6 km/h. |
| `morro_pixeles.py` | **0 errores**. Franja del coche 0,32–0,34 (se pide 0,25–0,61), centro x 0,50, neumáticos 81 000/73 000 px = 3,15 %/2,84 % (mínimo 0,5 %), las dos reglas (pintada y diferencia) coinciden en todos los casos. |
| `car_wheel_probe.gd` | **passed=true**, 0 errores. |
| `suspension_probe.gd` | **passed=true**, 0 errores. |
| `camera_probe.gd` | **0 errores**. Persecución intacta: distancia 11,38 m parado y 7,20 m a 200 km/h, factor de tamaño en pantalla 1,91. |
| `camera_pixels.py` | **passed=True**, 0 errores sobre las capturas de la persecución. |
| `runtime_probe.gd` | exit 0. |
| `pbr_probe.gd` | **PASS=true**. |

## 4. Comparación visual antes / después

- **Comparación controlada del encuadre** (`encuadre/comparativa-misma-pose.png`):
  misma pose, mismo instante con el reloj a cero, misma resolución y misma luz;
  lo único que cambia es el anclaje. Medido por diferencia de fotogramas:

| | antes (1,25/+0,25/61°) | después (1,70/+0,45/62°) |
|---|---|---|
| neumático izquierdo | 5,54 % del lienzo, tope y=0,604, x 0,069–0,335 | **3,21 %, y=0,652, x 0,217–0,361** |
| neumático derecho | 4,74 %, y=0,629, x 0,651–0,937 | **2,84 %, y=0,671, x 0,632–0,787** |
| franja del coche | 0,403 | 0,348 |
| holgura con el carenado | 0,097 m | **0,364 m** |

- Hoja completa: `comparativa-antes-despues.png` (morro antes/después, recortes
  del morro, persecución antes/después y recorte del coche).
- Capturas sueltas: `dispositivo/dispositivo-morro.png`,
  `dispositivo/dispositivo-persecucion-1.png`.
- Material del cuerpo, misma pose y misma luz: `materiales/import.png`,
  `materiales/antes.png`, `materiales/ahora.png` (comparación controlada; la
  diferencia entre el import original y el ajuste actual afecta al 0,46 % de
  los píxeles, sobre todo al azul del morro y al velo blanco del carenado).

## 5. Validación en el aparato (emulator-5558, 2424x1080)

APK instalado con `adb install -r`; la huella del paquete instalado coincide con
la del APK compilado (`5d55b3d9…`). Relanzado, acelerado con toques reales del
sistema y cambiado de vista con un `input tap` en el botón del HUD.

| medida | persecución | morro | morro acelerando |
|---|---|---|---|
| velocidad del HUD | 96,4 km/h | 91,4 km/h | 132,1 km/h |
| franja del coche | 0,000 | 0,263 | 0,261 |
| neumático izq. | 0,00 % | 4,24 % (y0 0,55) | 3,50 % (y0 0,67) |
| neumático der. | 0,00 % | 3,27 % (y0 0,68) | 3,25 % (y0 0,69) |
| fotogramas | 48,8 FPS | 46,4 FPS | — |

- Movimiento entre capturas separadas 0,35 s: 37,8 % / 29,1 % / 31,6 % de
  píxeles cambiados. El coche se mueve en las dos vistas.
- Cronómetro: 1 475 píxeles cambiados, delta máximo 241; la carrera no se
  detiene al cambiar de vista.
- `logcat` de la app: **0** líneas de error de material, textura o shader.
- Resultado del script: `errores=0 PASS=True`.

## 6. APK

- Ruta: `build/android/F1OneShot-BarcelonaMoto.apk`
- Tamaño: 247 770 063 bytes (236,3 MiB)
- SHA-256: `5d55b3d928fdc23b25570701e079f891d4f7ef7db5b7a98e59b40b6de2523966`
- Firmado con el almacén de depuración (el preset no tiene almacén de
  lanzamiento).

## 7. Qué queda pendiente / limitaciones

- El APK es de **depuración**: no hay keystore de release en el preset.
- En el emulador hicieron falta **tres** `input tap` sobre el botón de vista
  para que cambiara; los dos primeros (pulsaciones sintéticas de ~50 ms) no
  llegaron al botón. Con un dedo real no se ha podido probar aquí. Es un dato
  a vigilar, no un fallo del cambio de vista (la tercera pulsación lo cambia y
  el juego sigue corriendo).
- La comparación de persecución antes/después **no está igualada en
  velocidad** (antes a ~0 km/h, ahora a 96 km/h), así que sirve para ver el
  coche, no para medir nitidez; la comparación controlada de material es la de
  `materiales/`.
- El volante, el halo y el casco son piezas locales de la cámara (capa 2), no
  geometría del GLB; el modelo entregado no trae espejos.
- El giro visual de la rueda está topado a 36 rad/s: medido, 0,60 rad (34,4°) por
  fotograma a 60 FPS y 1,20 rad (68,8°) a 30 FPS; a 30 FPS se acerca al paso
  entre radios (72°) y la dirección aparente de la llanta puede volverse
  ambigua, aunque la letra del flanco sigue delatando el movimiento. En el
  aparato (46–49 FPS) son ~44° por fotograma. Bajar el tope a ~26 rad/s lo
  dejaría limpio también a 46 FPS, pero eso cambia un ajuste ya validado y no
  se ha hecho sin una medida de la llanta en movimiento (vídeo a 60 FPS del
  aparato).
