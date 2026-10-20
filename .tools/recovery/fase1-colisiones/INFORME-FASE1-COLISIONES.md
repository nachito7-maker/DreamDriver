# Fase 1 — Auditoría y corrección de colisiones

Estado: **Fase 1 cerrada** (auditoría de colisiones + la corrección de dirección que la
misma auditoría obligó a hacer). Sin tocar circuito, modelos, cámara, interfaz ni
configuración de pantalla.

Punto de partida estable y copia de recuperación:
`.tools/recovery/stable-20261014-pre-colisiones/` (scripts, escena, APK y SHA256SUMS del
estado restaurado, APK `605abf6a160454085636b2146fa8c0d33380b871b1da457b8203a91560dc563c`).

---

## 1. Qué se auditó

Se midió el circuito contra el coche, no el código: qué cuerpos de física existen, qué
bloquea al coche cuando se sale, si el agarre sigue a la superficie que se pisa y si el
muro que para el coche está dibujado donde se para.

| Prueba | Sonda | Qué mide |
| --- | --- | --- |
| Inventario de colisiones | `scripts/collision_inventory_probe.gd` | cada cuerpo de física: grupo, capa, caras, origen |
| Escapatorias | `scripts/offtrack_scan_probe.gd` | 306 columnas (estación × lado): ¿hay muro, o está abierta? |
| Agarre por superficie | `scripts/surface_grip_probe.gd` | 9 superficies: qué informa el juego y qué agarre aplica |
| Salida de pista | `scripts/offtrack_drive_probe.gd` | la maniobra real de salirse y volver |
| Movilidad fuera del asfalto | `scripts/offtrack_mobility_probe.gd` | 19 maniobras: ¿lo para un muro real o un borde invisible? |
| Impacto contra barrera | `scripts/barrier_impact_probe.gd` | 4 lanzamientos a 36 y 79 km/h contra el muro |
| Visibilidad del muro | `scripts/wall_visibility_probe.gd` | 6 puntos donde el muro está más cerca: dos vistas de cada uno |
| Vuelta completa | `scripts/driving_probe.gd` | una vuelta entera con los controles de toque reales |
| Sentido de la dirección | `scripts/steer_sign_probe.gd` | ¿el dedo a la derecha gira el coche a la derecha? |
| Dirección medida | `scripts/steering_probe.gd` | g sostenidas, radio, guiñada, oscilación |

## 2. Resultados de las pruebas

### 2.1 Inventario (`collision_inventory_probe-final.log`)
22 cuerpos de física en la pista: `TRM-BRC` (299 682 + 6 488 caras de la variante de
motos), `WALL` (3 848), `KERB` (16 515), `CURB` (13 819), `GRASS` (6 339), `GREEN` (7 269),
`OUT` (5 743 + 9 985), `SAND` (2 576), `RUMBLE` (3 628), `CONCRETE` (1 657), `GRAVEL` (436),
`CARPET` (817), `PITS` (95) y los cuerpos sin grupo declarado (`BUMP`, `MARBLES`, `GRILL`,
`CNCPTS`, `TRAV`). Los marcadores `AC_START`/`AC_TIME` (`4.obj`) se desactivan
(`collision_layer = 0`) para que no sean obstáculos. El coche usa capa 2 contra capa 1, con
una caja central de 1,2 × 0,55 × 3,4 m: los rayos de las sondas no lo tocan a él.

### 2.2 Escapatorias (`offtrack_scan_probe-final.log`)
306 columnas: **226** encuentran un muro entre 5,8 y 29,7 m (media 16,4 m), **80** quedan
abiertas y **0** columnas tienen un borde de superficie que cierre la salida antes que un
muro real. Es decir: lo único que cierra una escapatoria es una malla `WALL` del circuito.

### 2.3 Agarre fuera del asfalto (`agarre-antes.log` → `surface_grip_probe-final.log`)
Antes: 11 comprobaciones en fallo — el juego informaba `(sin dato)` de superficie y en
marcha **1 230 de 1 305 fotogramas** circulaban fuera del asfalto con agarre de asfalto
(p. ej. `GREEN: aplica 0.54, corresponde 0.58`).
Después: las 9 superficies se informan y aplican su propio agarre
(`TRM-BRC` 1,00 · `KERB/CURB/RUMBLE` 0,88 · `CONCRETE` 0,84 · `GRASS/GREEN/OUT/CARPET` 0,58
· `GRAVEL/SAND` 0,46), **0 desajustes en 1 337 fotogramas**.

### 2.4 Salida de pista y vuelta a la pista (`offtrack_drive_probe-final.log`)
5/5 PASS: el coche abandona el asfalto, recorre **70,07 m** sobre `OUT` con su propia física,
ningún contacto procede de la línea de IA de la pista, todas las colisiones coinciden con
geometría medida por rayos y el coche vuelve a la pista.

### 2.5 Movilidad: ¿barrera invisible o muro real? (`offtrack_mobility_probe-final.log`)
Antes: sólo 1 de 16 maniobras circulaba fuera del asfalto (FAIL «al menos 4»).
Después: **19 maniobras, 19 paradas contra la malla `WALL` real, 0 paradas contra un borde
bajo, 0 paradas contra un cuerpo sin cara vertical ni contacto de muro**; 8 de 19 recorren
≥ 50 m fuera del asfalto antes de la barrera y las 3 escapatorias que el barrido da por
abiertas dejan recorrer ≥ 15 m (18,2 · 36,6 · 7,4 m, esta última hasta el muro). Cada parada
lleva su barrido radial de 24 direcciones a 0,25 y 0,60 m, que sitúa la cara del muro a
1,4–1,8 m del coche.

Corrección de la propia sonda: antes clasificaba como «borde bajo invisible» toda parada en
la que el rayo frontal no encontraba cara vertical, incluso cuando su lista de contactos
decía `(WALL)`. Ahora decide el contacto instantáneo y el barrido radial lo corrobora.

### 2.6 Impacto contra barrera (`barrier_impact_probe-final.log`)
4/4 PASS a 36 y 79 km/h contra `WALL` en dos puntos del circuito: el contacto lo produce la
barrera del circuito, la malla que golpea es la misma que midió el rayo, la velocidad cae
por debajo del 60 %, el avance tras el golpe es 0,00–0,07 m, la penetración no llega a
0,5 m y el coche queda del lado de la pista.

### 2.7 Visibilidad del muro (`visibilidad-antes.log` + capturas)
En los 6 puntos donde el muro está más cerca de la trazada (5,8 · 6,1 · 6,2 · 6,6 · 6,8 ·
6,9 m) hay dos vistas por punto en `.tools/recovery/fase1-colisiones/shots/`
(`idx####_side#_salida.png` a la altura del morro y `idx####_side#_aerea.png` en oblicuo):
es la comprobación humana de que donde el coche se para hay barrera dibujada.

### 2.8 Vuelta completa con los controles de toque (`driving_probe-final.log`)
`FULL_LAP passed=true laps=1 best=527,96 s max_error_m=2,37 airborne_ticks=8
min_wheel_contacts=3 wall_hits=0 reposiciones_de_toque=3` y `LAP_TIMER armado=true`.
Una vuelta entera válida, sin tocar un solo muro y sin salirse de la pista.

### 2.9 Sentido de la dirección (`steer_sign-final.log`)
`mando=derecha valor=1.000 → giro −77,6°` y `mando=izquierda valor=−1.000 → giro +83,1°`:
2/2 PASS. Esta sonda es la que descubrió el fallo de sentido descrito abajo; ahora forma
parte de `verify.sh`.

### 2.10 Dirección medida (`direccion-antes.log` → `steering_probe-final.log`)

| Medida | Antes | Después |
| --- | --- | --- |
| g a 60 km/h, manillar a fondo | 0,26 g (radio 112 m) | 1,03 g (radio 28 m) |
| g a 120 km/h | 0,29 g (radio 397 m) | 1,10 g (radio 103 m) |
| g a 180 km/h | 0,33 g (radio 774 m) | 1,21 g (radio 207 m) |
| Primer cuarto del recorrido a 120 km/h | saturado (0,31 g de 0,31) | 0,34 g de 1,10 |
| Gira mientras acelera / frena | 0,28 / 0,26 g | 1,05 / 0,99 g |
| Oscilación de guiñada, frenando y girando | 0,38 (FAIL) | 0,40 (PASS: régimen regular) |

Ninguna curva produce contacto con muro, la guiñada no cambia de sentido y el recorrido del
mando se reparte de verdad: 25 % → 0,091, 50 % → 0,311, 75 % → 0,619, 100 % → 1,000.

## 3. Causa raíz de la dirección deficiente

1. **Sólo contaba un eje.** `lateral_limit = minf(front_limit, rear_limit)`, sin el factor 2
   por eje que sí usa cada eje en `front_limit`/`rear_limit`. El coche quedaba con la
   capacidad de un eje: 0,26 g, 397 m de radio a 120 km/h.
2. **Girar más giraba menos.** `understeer_factor` recortaba hasta un 32 % la guiñada por
   llevar el manillar girado, y el tope de guiñada usaba la fuerza de agarre *total* en vez
   de la fuerza lateral que el coche estaba entregando de verdad.
3. **Manillar saturado en el primer cuarto.** El tope de dirección era el de la moto, y el
   ángulo que satura el agarre cae como 1/v². A 120 km/h el primer cuarto del recorrido ya
   daba el máximo y el resto no hacía nada. Ahora `max_steer = min(lean_steer,
   grip_steer · 1,25)`.
4. **Inversión de sentido (fallo detectado durante esta fase).** Al convertir el tope de
   guiñada en una magnitud, el rango de `clampf` quedó invertido (mínimo positivo, máximo
   negativo) y la dirección giraba al revés. Lo cazó la sonda nueva
   `scripts/steer_sign_probe.gd`, que prueba el sentido de extremo a extremo.
5. **Freno analógico residual.** Los píxeles bajos del pedal producen peticiones de freno de
   ~4·10⁻⁸; cualquier residual cancelaba el par del motor y parecía que el coche no
   aceleraba. Ahora `brake_input ≤ 0,03` se considera cero, en un único sitio.

## 4. Archivos modificados

| Archivo | Cambio |
| --- | --- |
| `scripts/car_controller.gd` | 4 bloques: muestreo de superficie y voto mayoritario con los 4 rayos de rueda (con reserva por último contacto); tope de dirección limitado por el ángulo que satura el agarre; capacidad lateral = suma de ejes y tope de guiñada según la g lateral realmente entregada; freno residual a cero |
| `scripts/track_data.gd` | `classify_surface()` + `SURFACE_KEYS` (lee el grupo del nombre original de AC) y `ROAD` añadido al agarre de asfalto |
| `verify.sh` | nuevas comprobaciones `sonda_sentido` (sentido de giro) y espera `esperar_dispositivo()` antes de tocar el dispositivo |
| `scripts/controls_probe.gd` | vuelve a pisar los dedos si la ventana perdió el foco (como `driving_probe`) |
| `.tools/recovery/screen_check.py` | el mando se localiza por la raya vertical de su disco (más la firma del disco) en vez de por el color declarado del disco translúcido; cierre de huecos de 2 filas y camino de color suavizado para el vídeo. Corrige el falso fallo de `lienzo_final` (§6.6) |

Sondas nuevas o reescritas en esta fase: `collision_inventory_probe.gd`,
`offtrack_scan_probe.gd`, `surface_grip_probe.gd`, `offtrack_mobility_probe.gd`,
`barrier_impact_probe.gd`, `wall_visibility_probe.gd`, `steer_sign_probe.gd`,
`steering_probe.gd`, `offtrack_drive_probe.gd`, `driving_probe.gd`,
`line_curvature_probe.gd`, `drive_diag_probe.gd`, `headless_layout_check.gd`.

Registros de cada prueba: `.tools/recovery/fase1-colisiones/logs/`.
Capturas: `.tools/recovery/fase1-colisiones/shots/` (12 vistas de barrera) y
`.tools/recovery/integral/shots/` (pantalla, pantalla-final, reloj y el vídeo multitáctil
`toque/touch.mp4` con `toque/fases-velocidad-marcha.jpg`).

## 5. Compilación y pruebas automatizadas

`./verify.sh` completo (sin `SKIP_LONG`), 14 de octubre: **resultado OK, 29 comprobaciones,
ningún fallo obligatorio y ninguna comprobación omitida** (incluida la vuelta completa, que
en la corrida anterior iba marcada como omitida). Tabla completa en
`.tools/recovery/fase1-colisiones/logs/verify-fase1-6.log` y en
`verificacion-integral.json`.

APK final: `build/android/F1OneShot-BarcelonaMoto.apk`
`SHA-256 abc85b2b834a6cd8528eb8574a8bb5105f4790baf33e8cf282bea7c10bfb13e9` ·
247 667 130 bytes. La huella del `base.apk` extraído del emulador tras instalarlo coincide
byte a byte. La exportación sale del preset del proyecto (`compilar` y `firma` en la misma
corrida), así que el APK contiene el árbol actual: colisiones, superficies y dirección
incluidas. El APK de referencia del estado restaurado
(`605abf6a…`, guardado en `stable-20261014-pre-colisiones/`) sigue intacto.

| Comprobación | Resultado |
| --- | --- |
| 13 sondas de juego en el anfitrión (pista, materiales, runtime, controles, vuelta, inventario, escapatorias, agarre, dirección, sentido, movilidad, impacto, vuelta completa) | ok |
| Auditoría de materiales y de entrega del GLB | ok |
| Exportación Android + firma + huella del APK | ok |
| Instalación, huella instalada, arranque y registro sin errores | ok |
| Pantalla completa, lienzo sin bandas negras y HUD en su sitio | ok (2 veces: antes y después de conducir) |
| Toques reales: acelerador, freno, mando, multitáctil y liberación | ok |
| Cronómetro en el dispositivo | ok |
| Vueltas por segundo del anfitrión (referencia, no es un teléfono) | ok |

Vuelta completa del anfitrión en esta corrida: `FULL_LAP passed=true laps=1
best=527,96 s max_error_m=2,37 airborne_ticks=8 min_wheel_contacts=3 wall_hits=0`
(538 s de cómputo).

## 6. Comprobaciones en el dispositivo (APK instalado)

Ejecutadas con `.tools/recovery/fase3_device.sh` y `.tools/recovery/offtrack_device_check.py`
sobre `emulator-5556` (2400 × 1080, GPU host), con toques inyectados de verdad:

| Comprobación | Resultado | Evidencia |
| --- | --- | --- |
| Instalación del APK y huella | ok (`compilado = instalado`) | `.tools/recovery/fase3/logs/instalar.log`, `huella_instalada.log` |
| Arranque y HUD dibujado | ok | `.tools/recovery/fase3/logs/arranque.log` |
| **Salida de pista conduciendo de verdad** | **PASS** — el coche rueda fuera del asfalto: 10 intervalos medidos, cambio de imagen mínimo 0,127 (una barrera invisible lo habría dejado clavado) | `.tools/recovery/fase3/logs/offtrack_dispositivo.log`, `shots/offtrack/*.png` |
| Controles de toque (9 fases, multitáctil, freno+dirección) | PASS | `.tools/recovery/fase3/logs/toque.log`, `shots/toque/touch.mp4`, `touch.json` |
| Cronómetro | ok | `.tools/recovery/fase3/logs/cronometro.log` |
| HUD y mandos tras conducir | ok | `.tools/recovery/fase3/logs/lienzo.log` |
| Registro del dispositivo sin errores del juego | ok | `.tools/recovery/fase3/logs/registro.log` |

Capturas del juego funcionando: `.tools/recovery/fase3/shots/` (pantalla del circuito, frames
fuera del asfalto), `.tools/recovery/integral/shots/` (`pantalla.png`, `pantalla-final.png`,
`reloj-1/2.png`) y el vídeo de la secuencia multitáctil `shots/toque/touch.mp4` (1875
fotogramas a 25 fps).

### Lo que costó que estas pruebas fuesen fiables

No eran fallos del juego, eran fallos de la herramienta de medida, y se corrigieron:

1. **El inyector moría con la sesión de adb.** El servidor de adb de este equipo lo
   comparten el IDE y el emulador y se reinicia a ratos; al caer la sesión, el proceso
   inyectado recibía SIGKILL («Killed» en su registro) y la maniobra quedaba a medias.
   Ahora se lanza desprendido (`nohup setsid`), que sobrevive a `adb kill-server`.
2. **Un puntero táctil colgado bloqueaba el resto.** Tras un corte, el sistema conservaba
   el dedo pulsado de la sesión muerta y rechazaba todo `ACTION_DOWN` nuevo
   (`InputDispatcher: Invalid DOWN event - pointers already down`). Un reinicio del
   emulador limpia el estado; con (1) ya no vuelve a ocurrir.
3. **El filtro de errores del registro era demasiado ancho.** Contaba avisos del sistema
   que sólo mencionan el paquete (`E AppOps: attributionTag not declared in manifest`,
   `W WindowManager: Exception thrown during dispatchAppVisibility`) y el aviso del motor
   `E godot : WARNING: Failed to load cached shader`. Ahora usa el mismo criterio que el
   resto de la entrega (`check_logcat.py`): líneas graves y errores firmados por el motor.
4. **`verify.sh`** espera a que el dispositivo responda (`esperar_dispositivo`) y repite una
   vez las comprobaciones que dependen del transporte (`check_reintento`), sin relajar
   ningún criterio.
5. **`controls_probe`** vuelve a pisar los dedos si la ventana perdió el foco (el juego los
   suelta a propósito al perderlo), como ya hacía `driving_probe`.

### 6.6 El mando "se movía" sin moverse: la medición medía el fondo

La corrida anterior cerró con `lienzo_final` en **fallo** («el mando no está en su sitio»)
tras conducir de verdad. No era el juego: era la sonda. El mando del joystick se dibuja con
transparencia (`_draw_steering_knob`: disco con alpha 0,85), así que **su color medido lo
decide el fondo**. La sonda buscaba el color declarado `(33,43,53)` con tolerancia ±14 y en
la captura posterior a la conducción encontró **3 píxeles** —el disco se había desplazado a
`(35,58,65)` porque el coche acabó sobre otra superficie—, mientras que midiendo píxel a
píxel el mando estaba **exactamente en su centro** (`cx=185, cy=895`). El fallo era de la
medida, no del mando.

Corrección (`.tools/recovery/screen_check.py`): la posición del mando se mide por la **raya
vertical clara de su disco** (`Color(0.92,0.94,0.97,0.78)`), que se pinta sobre el propio
disco —oscuro— y por tanto no la tiñe el circuito: medida sale `(192,199,206)` al inicio y
`(191,200,207)` fuera de pista. Además del color se exige la **firma del disco**: a la altura
de la raya tiene que haber disco oscuro a los dos lados, que es lo que distingue el mando de
una franja clara del terreno. En el vídeo (H.264 4:2:0) el croma va submuestreado y la raya
se parte en trozos de 10-18 px, así que se cierran huecos de 2 filas y hay un camino de color
suavizado para ese caso.

Comprobado que sigue teniendo dientes (no se relajó ningún criterio, se cambió la magnitud
medida):

| Caso | Antes | Ahora |
| --- | --- | --- |
| Captura al inicio (2400×1080) | `cx=186` | `cx=185` |
| Captura tras conducir (la que falló) | 3 píxeles → **FAIL** | `cx=185` → PASS |
| Captura con el mando **desviado a mano** en el emulador (swipe real sostenido) | — | `cx=248` → **FAIL** |
| Captura tras soltar | — | `cx=185` → PASS |
| Serie del vídeo multitáctil (2 167 fotogramas) | 0 nulos, desvío máx 290 | 10 nulos, reposo 185, desvío máx **303** |

La misma corrida completa de `verify.sh` pasó `lienzo_final` con `cx=185, cy=893`, y la sonda
de toque siguió detectando las nueve fases (reposo, acelerador, freno, multitáctil, retorno,
freno+dirección, liberación). Evidencias: `control-mando/1-reposo.png`,
`control-mando/2-desviado.png`, `control-mando/3-soltado.png` y
`review/crops/mando-comparacion.png` (el mando centrado en las dos capturas que la sonda
enfrentaba).

## 7. Limitaciones pendientes

- La vuelta completa del anfitrión tarda 527,96 s porque el piloto de la sonda es
  conservador (objetivo 6–10 m/s); no es un límite del coche.
- Las 80 columnas abiertas del barrido se clasificaron por rayos; se han conducido 19
  maniobras (8 estaciones fijas × 2 modos + 3 escapatorias abiertas automáticas), no las 80.
- La visibilidad del muro se documenta con capturas para revisión humana; no hay una
  comprobación automática de que la malla dibujada sea la misma que la de colisión.
- Todo lo medido en el dispositivo es el emulador `F1Recovery` (4 GB, GPU host); no hay
  pruebas en un teléfono físico ni en otros tamaños de pantalla, ni perfilado térmico.
- Los fotogramas por segundo del anfitrión son una referencia, no una medida de teléfono.
- La medición del mando se revisó contra las **115 capturas de 2400×1080** guardadas y los
  **2 167 fotogramas** de la grabación. Todas las capturas de mando en reposo del árbol
  actual dan lo mismo —`cx=185, cy=893` frente al centro nominal `186, 895`— tanto al inicio
  como tras salirse de pista (hierba, asfalto y pintura de escape); 26 capturas no dan
  lectura (builds anteriores, con otro dibujo del mando, o estados sin HUD) y 9 leen el mando
  desviado, todas correctamente lejos del centro. Los dos únicos fotogramas que se
  resistieron —de una sonda anterior, `fase3/shots/offtrack/t20-t22.png`, fondo oscuro con
  una franja vertical clara pegada a la esquina del mando— leyeron esa franja (`cx=67`) en vez
  del mando. En los dos el mando está desviado, así que el veredicto («no está en el
  centro») es el mismo y sólo cambia la cifra. Esa frontera es la del propio mando (elemento
  translúcido); se cierra del todo con una plantilla de forma, más código del que el harness
  necesita hoy.

## 8. Siguientes pasos

1. Probar el APK en un teléfono Android real (táctil capacitivo y térmica) y en un segundo
   tamaño de pantalla, para comprobar que `_layout_controls` (que escala por altura de
   lienzo) sigue cumpliendo las regiones que mide `screen_check.py`.
2. Decidir si las escapatorias sin barrera (80 columnas) son diseño deseado o quieren
   barrera; si se añade, hay que volver a pasar `sonda_escapatorias` y `sonda_movilidad`.
3. Convertir la hoja de contacto del toque
   (`integral/shots/toque/fases-velocidad-marcha.jpg`) en revisión humana firmada de las
   nueve fases, hoy automática.
4. Si se quiere medir el mando también en fondos oscuros con franjas claras, la vía es
   con una plantilla de forma (el disco completo) en vez de un color: no es necesario para
   lo que el harness mide hoy.

---

## 9. Entrega del 14 de octubre (cierre de esta fase)

| | |
| --- | --- |
| APK | `build/android/F1OneShot-BarcelonaMoto.apk` |
| Tamaño | 247 667 130 bytes |
| SHA-256 | `abc85b2b834a6cd8528eb8574a8bb5105f4790baf33e8cf282bea7c10bfb13e9` |
| Huella del APK instalado en el emulador | idéntica a la del compilado |
| Corrida completa `./verify.sh` | OK · 29 comprobaciones · 0 fallos obligatorios · 0 omitidas |
| Estado estable de partida | `stable-20261014-pre-colisiones/` (APK `605abf6a…` y fuentes) |
| Copia de recuperación de lo tocado | `stable-20261014-pre-colisiones/tools-recovery/screen_check.py` (idéntico al original antes del cambio) |

Capturas del juego funcionando y de la prueba del mando:

- `shots-entrega/00-hoja-de-contacto.png` — la pantalla al inicio y después de conducir.
- `shots-entrega/01-pantalla-al-inicio.png` (2400×1080, HUD y mandos en su sitio).
- `shots-entrega/02-pantalla-tras-conducir.png` (cronómetro a 58 s, coche en pista).
- `shots-entrega/03-fases-toque-velocidad-marcha.jpg` — las nueve fases del toque, una fila
  por fase, con velocidad y marcha medidos en pantalla.
- `shots-entrega/1-reposo.png`, `2-desviado.png`, `3-soltado.png` — control del mando:
  centro → desviado a mano en el emulador → centro.
- `shots-entrega/04-mando-antes-despues-del-fallo.png` — el mando centrado en las dos
  capturas que la sonda enfrentaba (la del inicio y la del falso fallo).
- `shots-entrega/03-touch.json` — los 34 números medidos del toque (presiones, píxeles
  cambiados de velocidad y marcha, recorrido del mando).

Pruebas automatizadas reproducibles: `./verify.sh` (todo), o una a una con
`--headless --path . --script scripts/<sonda>.gd` (las de toque necesitan ventana).
