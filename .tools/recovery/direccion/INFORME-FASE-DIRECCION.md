# Regresión de dirección: el coche apenas giraba

Fecha: 15-oct-2026. Proyecto: F1 One Shot Barcelona Moto (Godot 4.7.2, Android).

Registro de la intervención completa: causa, medición antes/después, archivos tocados y
validación en el dispositivo. Todo lo que dice este informe sale de una sonda o de un
registro guardado; las rutas están al lado de cada número.

---

## 1. Causa raíz demostrada

**El recorrido útil del mando se había quedado reducido al último tramo del anillo a media
y alta velocidad.** No era el modelo de física (a fondo de mando el coche giraba 1,10 g a
120 km/h), ni el mando táctil (el dedo llegaba al fondo), ni las ruedas: era la **curva del
joystick**, que entregaba la demanda muy comprimida, sobre un tope de dirección que desde el
14-oct se recorta con el agarre (∝ 1/v²).

Las dos piezas, por separado, tienen sentido:

* `scripts/car_controller.gd` limita el ángulo máximo a esta velocidad con
  `max_steer = min(lean_steer, grip_steer × 1,25)`, donde `grip_steer` es el ángulo que
  satura el agarre y cae como 1/v². A 120 km/h deja **2,58°** de tope frente a los 18,35°
  del tope del manillar: el mando tiene que repartir todo su recorrido en ese margen para
  que a fondo de mando se alcance el agarre.
* `scripts/touch_controls.gd` convertía el recorrido del dedo en demanda con
  `pow(magnitude, 1.6)`: **a medio recorrido entregaba el 31 % de la demanda y a un cuarto,
  el 9 %**.

Juntas, el 88 % del anillo hacía falta para llegar al agarre:

```
DIRECCION INFO recorrido del dedo -> demanda del mando: 10%→0.013  25%→0.091  50%→0.311  75%→0.619  100%→1.000
DIRECCION_RESULT 120 km/h, recorrido 25 % a la derecha | demanda=0.091 aplicado=0.23° g_sostenida=0.125 radio=912 m
DIRECCION_RESULT 120 km/h, recorrido 50 % a la derecha | demanda=0.311 aplicado=0.80° g_sostenida=0.428 radio=265 m
DIRECCION_RESULT 240 km/h, recorrido 50 % a la derecha | demanda=0.311 aplicado=0.26° g_sostenida=0.541 radio=815 m
DIRECCION_RESULT 240 km/h, recorrido 25 % a la derecha | demanda=0.091 aplicado=0.08° g_sostenida=0.158 radio=2813 m
```

Con el pulgar a media carrera (medio anillo) el coche describía radios de 265 m a 120 km/h y
de 815 m a 240 km/h: en la práctica, recto. Y **a poca velocidad no se notaba** porque ahí el
tope del agarre no interviene (22-25° disponibles) y medio recorrido ya da un radio de 43 m:
de ahí el síntoma exacto del encargo, «apenas gira y sólo responde cuando circula muy
despacio».

Medido en `.tools/recovery/direccion/logs/antes.log` (curva anterior, exponente 1,6) y
`.tools/recovery/direccion/logs/despues-2.log` (corregida). Los dos con la misma sonda, el
mismo árbol y la misma versión de física.

Antecedente (histórico, en `.tools/recovery/fase1-colisiones/logs/direccion-antes.log`): antes
del 14-oct el tope NO se recortaba con el agarre, así que el coche tenía 18-25° de ángulo a
cualquier velocidad, pero **sólo podía usar 0,26-0,33 g** de agarre lateral: giraba el volante
mucho y el coche no hacía la curva (subviraje). El modelo actual (1,10-1,36 g) es el bueno;
lo que faltaba era que el mando entregase su recorrido de forma utilizable.

---

## 2. Archivos y parámetros modificados

| Archivo | Cambio |
|---|---|
| `scripts/touch_controls.gd` | **La corrección.** Curva del mando: zona muerta 0,035 → 0,04 y exponente **1,6 → 0,90** (`STEER_DEAD_ZONE`, `STEER_CURVE_EXPONENT`). Nueva función `steering_travel_for(demanda)`, la inversa exacta de la curva, para que las sondas que conducen por el canal táctil pidan una demanda concreta sin repetir constantes. |
| `scripts/car_controller.gd` | Sólo instrumentación: `debug_lean_steer`, `debug_grip_steer`, `debug_max_steer`, `debug_target_steer`, `debug_yaw_cap`, `debug_lateral_limit_g` (los topes de la cadena, para poder medir en qué eslabón se pierde el giro) y `_report_steering_telemetry()` (una línea `[mando]` cada 0,5 s, **sólo en compilación de depuración**). Ninguna línea cambia la física. |
| `scripts/steering_response_probe.gd` | **Nueva sonda** (`verify.sh` → `sonda_mando`): mide la cadena completa empujando el anillo del mando con toques reales. 60 comprobaciones. |
| `scripts/driving_probe.gd`, `scripts/drive_diag_probe.gd` | Dejan de llevar copiada la inversa de la curva vieja (`pow(d, 1/1,6) × 0,965 + 0,035`) y usan `ui.steering_travel_for(d)`: si la curva cambia, la sonda sigue pidiendo la misma demanda física. |
| `verify.sh` | Nueva comprobación obligatoria `sonda_mando` (dirección por el mando táctil, en el anfitrión) y nueva `mando_dispositivo` (dirección con dedos reales en el aparato). |
| `.tools/recovery/AndroidTouch.java` | Modo `mando` (undécimo argumento): maniobra de dirección con el inyector — acelerador a fondo y mando al fondo a cada lado. No toca la secuencia de fases que usan las demás comprobaciones. |
| `.tools/recovery/screen_check.py` | Orden `mando`: ejecuta esa maniobra y lee las líneas `[mando]` del registro del aparato para comprobar el giro. |

No se ha tocado: la física de neumáticos y guiñada, la suspensión, la geometría del circuito,
las colisiones, la cámara, la línea de asistencia, los pedales, el HUD.

---

## 3. Mediciones: entrada, ángulo aplicado y respuesta

Mando táctil real (`_handle_touch_down` / `_handle_touch_motion` sobre el anillo), velocidad
sostenida, losa de asfalto plana. `g` = aceleración lateral sostenida; radio = v²/g efectivo.

### 3.1 Lo que entrega el mando (recorrido del dedo → demanda)

| Recorrido | Antes (exponente 1,6) | Después (exponente 0,90) |
|---|---|---|
| 10 % | 0,013 | 0,082 |
| 25 % | 0,091 | 0,255 |
| 50 % | 0,311 | 0,516 |
| 75 % | 0,619 | 0,762 |
| 100 % | 1,000 | 1,000 |

### 3.2 Respuesta a 120 km/h, mando a la derecha, velocidad sostenida

| Recorrido | Antes: ángulo aplicado | Antes: g / radio | Después: ángulo aplicado | Después: g / radio |
|---|---|---|---|---|
| 10 % | 0,03° | 0,018 g / 6189 m | 0,21° | 0,113 g / 1001 m |
| 25 % | 0,23° | 0,125 g / 912 m | 0,66° | 0,350 g / 324 m |
| 50 % | 0,80° | 0,428 g / **265 m** | 1,34° | 0,709 g / **159 m** |
| 75 % | 1,61° | 0,851 g / 132 m | 1,99° | 1,048 g / 107 m |
| 100 % | 2,61° | 1,098 g / 102 m | 2,61° | 1,098 g / 102 m |

### 3.3 A las demás velocidades (medio recorrido y a fondo)

| Velocidad | Medio recorrido: antes | Medio recorrido: después | A fondo (igual antes y después) |
|---|---|---|---|
| 60 km/h | 0,397 g / 72 m | **0,659 g / 43 m** | 1,029 g / 28 m |
| 120 km/h | 0,428 g / 265 m | **0,709 g / 159 m** | 1,098 g / 102 m |
| 180 km/h | 0,476 g / 530 m | **0,789 g / 318 m** | 1,211 g / 206 m |
| 240 km/h | 0,541 g / 815 m | **0,895 g / 488 m** | 1,361 g / 319 m |

La media del recorrido (medio anillo) pasa de entregar el 39-42 % del giro máximo al
**64-66 %**, que es lo que se exige (≥ 60 %). El primer 10 % sigue siendo suave (0,11-0,14 g,
radios de 1-3 km): no se ha vuelto un mando nervioso.

### 3.4 El ángulo pedido llega a las ruedas

El ángulo de la rueda delantera **en pantalla** (medido sobre la base que el modelo le pone al
nodo, descontando la rodadura y la actitud de la suspensión) es el ángulo aplicado por el
modelo, con un desvío peor de **0,01°** en los 33 casos, y gira hacia el lado que pide el
mando. Y el aplicado es el tope de esa velocidad (relación aplicado/tope 0,80-1,00), así que
la pérdida de giro no está en el camino mando→ruedas.

---

## 4. Batería de curvas, transiciones y comparación izquierda/derecha

`sonda_mando` (`scripts/steering_response_probe.gd`), 33 casos = 4 velocidades × 5 recorridos
a la derecha + 2 recorridos a la izquierda × 4 velocidades + 5 casos de pedal (sosteniendo,
acelerando y frenando), **60 comprobaciones**:

* giro a baja (60), media (120) y alta (180-240) velocidad;
* curva lenta, media y rápida: radio 28-43 m (60 km/h), 102-159 m (120 km/h), 206-319 m
  (180-240 km/h);
* progresividad: el giro crece con el recorrido en las cuatro velocidades;
* mando a fondo = todo el agarre disponible (1,03 / 1,10 / 1,21 / 1,36 g);
* izquierda = derecha con 0 % de diferencia en las cuatro velocidades;
* transición de lado: los dos sentidos dan la misma magnitud y la guiñada cambia de signo;
* acelerando y girando: 1,05 g a 60 km/h, 0,74 g a 120 km/h con medio anillo;
* frenando y girando: 0,98 g a 180 km/h (los dos lados) y 0,50 g a 240 km/h;
* sin contacto con muro en ninguna medida (la losa de pruebas está limpia).

Resultado: **`DIRECCION comprobaciones=60 fallos=0`**. El mismo árbol con la curva anterior da
**fallos=6** (los cuatro de «recorrido medio» y los dos de pedal), que es la medida de la
regresión que sufría el jugador.

---

## 5. Resultado de `./verify.sh`

Corrida completa sobre el árbol corregido: **53 comprobaciones, 51 en verde, 2 en rojo, salida 1**.
Registro: `.tools/recovery/integral/verify-correccion.log`; por comprobación,
`.tools/recovery/integral/checks.tsv`; informe, `.tools/recovery/integral/verificacion-integral.json`.

Las dos que fallan son medidas de **píxeles de otras fases** (encuadre de cámara y color de la
calzada), fallan igual que antes de tocar la dirección y ninguna de las líneas modificadas
interviene en ellas (§8). Todo lo demás, en verde, incluido lo de dirección:

| Comprobación | Qué mide | Resultado |
|---|---|---|
| `sonda_mando` | la cadena del mando táctil: 33 casos, 4 velocidades, los dos lados, con pedal | **60 comprobaciones, 0 fallos** |
| `sonda_direccion` | la respuesta medida con la sonda de dirección | PASS (a fondo: 1,03 / 1,10 / 1,21 g a 60 / 120 / 180 km/h) |
| `sonda_sentido` | que el mando a izquierda gira a izquierda | PASS (giro 63,7° a 50 km/h) |
| `sonda_conduccion` | vuelta completa al circuito por el canal táctil | PASS (1 vuelta, 528,24 s, error máx. de trazada 2,37 m, **0 golpes con muro**) |
| `sonda_controles` | la curva declarada del mando y los pedales | PASS |
| `mando_dispositivo` | el joystick real en el aparato | PASS, 10 comprobaciones (§7) |
| `toque` | acelerador, freno, mando y entradas simultáneas en la pantalla del aparato | PASS |
| `cronometro`, `pantalla`, `lienzo`, `lienzo_final`, `arranque` | HUD, orientación y lienzo en el aparato | PASS |
| `sonda_ruedas`, `sonda_suspension`, `sonda_agarre` | ruedas, suspensión y adherencia por superficie | PASS |
| `sonda_camara`, `audit_camara`, `camara_dispositivo`, `morro_dispositivo` | cámara y morro (anfitrión y aparato) | PASS |
| `sonda_impacto`, `sonda_movilidad`, `sonda_escapatorias` | colisiones y salidas de pista | PASS |
| `compilar`, `firma`, `empaquetado`, `instalar`, `huella_instalada` | APK e instalación | PASS |

## 6. APK

| | |
|---|---|
| Ruta | `build/android/F1OneShot-BarcelonaMoto.apk` |
| Tamaño | 247.630.592 bytes (236,2 MiB) |
| SHA-256 | `a3b582b941a8fb1861ffcc13af887adca3d1b3e3253f702c3f79c47badef6fef` |
| Compilado | 15-oct-2026 21:23:27 (`compilar` 14 s, `firma` y `empaquetado` en verde) |

## 7. Instalación y prueba en Android

Aparato: emulador `emulator-5556` (`sdk_gphone16k_arm64`), Android del SDK instalado.
La huella del APK **instalado** coincide con la compilada (`huella_instalada`: compilado =
instalado = `a3b582b9…`), así que lo medido es exactamente este binario.

`sonda_mando` en el aparato, con dedos reales sobre el joystick del juego (inyector
multitáctil, maniobra que alterna los lados y mide mientras el coche rueda):
registro `.tools/recovery/integral/logs/mando_dispositivo.log`, medida cruda
`.tools/recovery/direccion/device/mando.json`, **PASS en las 10 comprobaciones**:

```
MANDO PASS el dedo al fondo del mando pide casi toda la demanda a la derecha (+1.000 ≥ 0,80)
MANDO PASS el ángulo pedido llega a las ruedas: el aplicado es el tope de la velocidad (relación 1.00)
MANDO PASS las ruedas giran hacia el lado que pide el mando a la derecha
MANDO PASS a 309,6 km/h hay capacidad de giro real a la derecha (-0,98 g sostenida ≥ 0,6; pico -1,62 g)
MANDO PASS el coche gira de verdad a la derecha (guiñada mediana -0,111 rad/s, máxima -0,220)
MANDO PASS el dedo al fondo del mando pide casi toda la demanda a la izquierda (-0.858 ≥ 0,80)
MANDO PASS el ángulo pedido llega a las ruedas: el aplicado es el tope de la velocidad (relación 0.86)
MANDO PASS las ruedas giran hacia el lado que pide el mando a la izquierda
MANDO PASS a 79,7 km/h hay capacidad de giro real a la izquierda (1,05 g ≥ 0,6 g)
MANDO PASS el coche gira de verdad a la izquierda (guiñada mediana +0,351 rad/s, máxima +0,473)
MANDO PASS los dos lados giran al revés el uno del otro (derecha -0,111 / izquierda +0,351 rad/s)
```

Es decir: con el dedo al fondo, a 80 km/h el coche sostiene **1,05 g** y a 310 km/h **-0,98 g**
(1,62 g de pico) — lo mismo que mide el anfitrión con la misma curva (1,10-1,36 g según
velocidad), así que la corrección viaja en el APK y funciona con el mando real.

## 8. Problemas pendientes

* **Las dos comprobaciones en rojo de `./verify.sh` son de otras fases, no de dirección.** Son
  las únicas que se repiten entre la corrida anterior a la corrección (20:44 del 15-oct, que
  marcaba cinco fallos: las tres de dirección ya están arregladas) y ésta; ninguna de las
  líneas tocadas (curva del mando, telemetría de depuración) interviene en ellas.
  * `camara_pixeles` —¿crece el coche en pantalla al acelerar, en el aparato?— falla en el
    primer escalón, de 0 a 41 km/h (189 → 173 px). Medido sobre el fotograma de esta corrida
    (`.tools/recovery/integral/shots/camara/disp-001.png`): el componente que el clasificador
    de librea toma por coche **absorbe un mástil del mundo** —una columna de sólo 14-26 px de
    ancho, rgb≈(7,60,14), en las filas y=539..611— que se une a la mancha del coche en la
    salida; las filas anchas del coche empiezan 80 px más abajo. Es un defecto de la MEDIDA
    (`camera_pixels.py`), no del encuadre: el anfitrión, con la misma ley de cámara, mide
    155 px parado y 298 px a 200 km/h (factor 1,94, `audit_camara` en verde), y el resto de la
    serie del aparato crece como toca (173 → 298 → 357 → 369 px, factor 1,95).
  * `linea_dispositivo` —¿sale azulada la calzada del aparato?— da dominante mediana de azul
    19,0 sobre 255 en `disp-005.png` (umbral 8,0). Medido: en TODOS los fotogramas la franja
    baja de la ventana de medida (y ≥ 772 de 1080, el asfalto más cercano a la cámara, detrás
    del coche) tiene b−r = 19, mientras el asfalto a pleno sol, más lejos, tiene 3-8; la
    mediana salta de 7 a 19 según cuánta franja cercana entra en el cuadro, y por eso la
    comprobación pasa con el coche parado y falla en cuanto acelera. La franja de goma de la
    trazada —lo que esta comprobación vigila— está verificada en el anfitrión (`audit_linea`,
    en verde) y el verde de la línea sí se ve en el aparato (12.477 px a 263 km/h).
* La medida de la respuesta se hace con la velocidad sostenida y sobre una losa plana: dice
  del modelo, no del circuito. La conducción real (vueltas con el autopiloto de la sonda
  `sonda_conduccion` y los vídeos del dispositivo) queda también en la verificación integral.
* El emulador de este equipo da unos 5 fotogramas por segundo, así que el juego avanza muy por
  debajo del tiempo real: en el aparato el coche no llega a la velocidad que alcanza en el
  anfitrión, y por eso las comprobaciones de dispositivo exigen umbrales de giro que se
  cumplen a cualquier velocidad por encima de 40 km/h.
* El tope de dirección sigue recortándose con el agarre (∝ 1/v²). Es lo correcto —es lo que
  hace que el mando reparta su recorrido y que a fondo se alcance el agarre sin derrapar— y
  ahora se mide en cada pasada: `tope=[lean 18,39° agarre 2,08° max 2,60°]` a 120 km/h.
