# FASE CÁMARA — La cámara se aleja al correr

Fecha: 14 de octubre de 2026. Estado: **cerrada y medida en el anfitrión y en el
dispositivo, con la batería de regresión en verde** (§9).

---

## 0. Resumen de una frase

El coche parecía alejarse porque la cámara no medía su distancia en el sistema del
coche, sino con un suavizado exponencial sobre una referencia **móvil**: ese filtro
se queda con un error de seguimiento permanente de `v/λ` metros, así que la
separación crecía 9 m entre parado y 200 km/h sin que ninguna línea cambiase la
distancia. Ahora la distancia se calcula en el sistema del coche, es decreciente
con la velocidad (11,4 m parado → 7,2 m a tope) y sólo se filtra el parámetro de
velocidad. El coche pasa de ocupar el **20,4 %** del alto de pantalla parado y el
**8,2 %** a 200 km/h (la queja) a ocupar el **14,4 %** parado y el **27,6 %** a
200 km/h: un factor **1,92× más grande al correr** en vez de 2,5× más pequeño.

---

## 1. Lo que pedía la fase y qué se entrega

| Requisito | Estado | Evidencia |
|---|---|---|
| 1. Auditar el cálculo actual de posición y orientación | hecho | §2 |
| 2. Averiguar por qué el coche se aleja al acelerar | hecho, **cuantificado** | §3 |
| 3. Comprobar si hay desplazamiento dinámico, interpolación, escalado o FOV variable | hecho | §2 y §3 |
| 4. Distancia inversamente proporcional a la velocidad, con topes y transición suave | hecho | §5, `scripts/race.gd` |
| 5. A poca velocidad, distancia cómoda para maniobrar | hecho | 11,4 m parado, 10,3 m a 50 km/h |
| 6. A mucha velocidad, cámara cerca y coche grande | hecho | 7,2 m y 298 px de alto a 200 km/h |
| 7. Sin saltos, vibraciones ni cambios bruscos | medido | ≤ 0,017 m por fotograma, 0 cambios de sentido |
| 8. Coche bien encuadrado y pista visible por delante | medido | margen ≥ 80 px a 200 km/h; puntos a 20/40/60 m dentro del cuadro |
| 9. Altura y ángulo para anticipar curvas | hecho | 3,45 m parado → 2,70 m a tope, con adelanto del punto de mira 11 → 24 m |
| 10. No tocar modelo, posición del coche ni circuito | hecho | la cámara es de sólo lectura sobre el coche y el circuito |
| 11. No usar el FOV como único recurso | hecho | **el FOV no se toca**: 72° en los 13 casos medidos |
| 12. Rendimiento para Android | medido | §8 |

Pruebas obligatorias (§6): parado, 50, 100, 150, 200, desaceleración desde alta
velocidad, con capturas comparativas y medida del tamaño del coche en pantalla.

---

## 2. Auditoría: cómo se calculaba la cámara

La cámara anterior vivía en `scripts/race.gd` y era esto (el modo `legacy` de la
sonda lo reproduce línea por línea, así que la medida se hace sobre el mismo código
que estaba en el juego, no sobre un recuerdo):

```gdscript
# _process, una vez por fotograma dibujado
var forward := -car.global_basis.z
var target := car.global_position + Vector3.UP * 3.4 - forward * 9.0
eye = eye.lerp(target, 1.0 - exp(-delta * 6.0))       # λ = 6 s⁻¹
camera.global_position = eye
camera.look_at(car.global_position + forward * (12.0 + car.speed_mps * 0.15) + Vector3.UP * 0.8)
```

Lo que hay y lo que no hay en ese código:

* **No hay FOV variable.** El FOV era y sigue siendo 72° fijo. La hipótesis del FOV
  queda descartada por lectura y, además, medida (`fov: 72.0` en los 13 casos).
* **No hay cambio de escala del modelo** ni de la posición del coche.
* **No hay escalado explícito de distancia**: el multiplicador `* 9.0` es una
  constante. Aparentemente, entonces, la distancia no debería cambiar con la
  velocidad… y esa es justo la trampa.
* **Sí hay un desplazamiento dinámico: el punto de mira**, `12 + v·0,15`. A 191 km/h
  mira 20 m por delante en vez de 12 (esto es lo único que crecía con la velocidad
  y, como se ve en §7, no es la causa del tamaño).
* **Sí hay interpolación, y es la causa**: `eye.lerp(target, 1-exp(-6·delta))`.

### Qué hace ese filtro

`eye` es la posición suavizada y `target` se traslada con el coche a `v` m/s. Un
filtro exponencial de primer orden contra un objetivo que se mueve a velocidad
constante **no converge al objetivo**: converge a una posición retrasada una
distancia fija. En régimen estacionario,

```
eye ≈ target - v/λ          (λ = 6 s⁻¹)
```

es decir, el error de seguimiento es `v/6` metros **con el signo de quedarse atrás**,
y "atrás" (medido sobre la dirección de marcha) es exactamente hacia fuera del
coche: la cámara se va 4,95 m más lejos a 107 km/h y 8,8 m más lejos a 191 km/h,
sobre los 9 m de separación base. Es un error del filtro, no una decisión de diseño,
y crece linealmente con la velocidad: por eso el coche "se alejaba" en las capturas
del usuario sin que hubiera ninguna línea que lo hiciera.

---

## 3. La causa, medida y comparada con la predicción

La sonda mide la cámara anterior y la nueva con el mismo instrumento
(`scripts/camera_probe.gd` y `-- legacy`). Distancia real de la cámara al coche
sobre el plano, a la velocidad que el coche sostiene con gas real:

| Velocidad | Predicción `9,0 + v/6` | Medido, cámara anterior | Desvío del modelo |
|---|---|---|---|
| 0,7 km/h | 9,03 m | **9,03 m** | 0,00 m |
| 50,3 km/h | 11,31 m | **11,27 m** | −0,04 m |
| 100,0 km/h | 13,63 m | **13,52 m** | −0,11 m |
| 107,0 km/h | 13,95 m | **13,83 m** | −0,12 m |
| 149,5 km/h | 15,92 m | **15,75 m** | −0,17 m |
| 189,7 km/h | 17,85 m | **17,57 m** | −0,28 m |
| 198,4 km/h | 18,19 m | **17,96 m** | −0,23 m |

El modelo `9 + v/6` reproduce lo medido con un error menor de 0,3 m en todo el rango
(≤ 1,6 %, y el residuo es la componente vertical y el reparto entre giro y traslación).
Eso cierra la causa: **era el filtro sobre una referencia móvil.**

### Segunda causa, más pequeña y también real: la fase del reloj

La cámara se resolvía en `_process` (ritmo de dibujado) mientras el coche se mueve en
`_physics_process` (120 Hz en este proyecto). Entre un fotograma dibujado y el
siguiente el coche avanza, y la cámara se quedaba con la posición **anterior**: 0,92 m
de separación extra a 200 km/h con el dibujado a 60 Hz, y temblor cuando los dos
relojes se desfasaban (que es el "saltito" que se veía en el dispositivo, donde la
tasa de dibujado es baja e irregular). Ahora la cámara se resuelve en el paso de
física con `process_physics_priority = 10`, la misma fase que el coche y **después**
de que éste se haya movido.

---

## 4. Lo que NO era

Para que no quede duda de lo descartado, con la medida delante:

* **FOV**: constante a 72° en los 13 casos medidos de la cámara nueva. No interviene.
* **Tamaño del modelo**: `assets/RedBull.tscn` y su `.glb` no se tocan en esta fase.
  La caja del coche proyectada mide lo mismo (1,34–1,46 m de alto según la actitud de
  suspensión de cada caso) antes y después.
* **Geometría del circuito**: `assets/BarcelonaMoto-Tutorial.glb` intacto.
* **Resolución**: las medidas del anfitrión se hacen sobre un lienzo de **2400×1080**
  en un `SubViewport`, con el mismo alto que el teléfono (1080 px, que es lo que fija el
  encuadre: el FOV de la cámara es vertical; el aparato da 2424 px de ancho). El tamaño
  en píxeles se comprueba además sobre los ficheros PNG
  (`.tools/recovery/camera_pixels.py`), no con cuentas internas, y como fracción del
  alto es independiente de la resolución.

---

## 5. La corrección

Cambio en `scripts/race.gd`. La ley es una interpolación lineal del parámetro
`blend = v / v_max` con `v_max = 55 m/s` (≈ 198 km/h: **el tope declarado de la ley**,
no el techo del coche —éste llega a 263 km/h en la recta, §9.3—), y topes declarados y
exportables:

| Parámetro | Valor | Por qué |
|---|---|---|
| `camera_distance_stopped_m` | 11,4 m | maniobrar cómodo: se ve el coche entero y su entorno |
| `camera_distance_fast_m` | 7,2 m | deportivo: el coche ocupa el 27,6 % del alto a 200 km/h |
| `camera_height_stopped_m` → `camera_height_fast_m` | 3,45 → 2,70 m | bajar al acercarse mantiene el ángulo de anticipación |
| `camera_ahead_stopped_m` → `camera_ahead_fast_m` | 11,0 → 24,0 m | al acercarse hay que **mirar más lejos** para no perder la pista por delante |
| `camera_tau_closing` / `camera_tau_opening` | 0,55 / 0,85 s | acercarse es la respuesta deportiva; alejarse recupera despacio |
| `camera_tau_yaw` / `camera_max_yaw_lag_rad` | 0,20 s / 0,44 rad (25°) | la cámara se queda un poco por fuera en curva, acotado |
| `camera_min_distance_m` | 3,6 m | nunca dentro del coche |
| `camera_wall_margin_m` / `camera_tau_wall` | 0,35 m / 0,08 s | anticolisión acortada y filtrada |
| `camera_squeeze_ratio` | 0,25 | si el muro obliga a acortar, la cámara **baja** en la misma proporción |

Las decisiones que importan, explicadas:

1. **La distancia se construye en el sistema del coche**, no filtrando la posición:
   `camera.global_position = car.global_position + UP·altura - flat·distancia`. Así el
   régimen estacionario no tiene error, a cualquier velocidad y a cualquier frecuencia
   de dibujado. Lo que se filtra es el **parámetro**, no la geometría.
2. **Filtro asimétrico**: acercarse rápido, alejarse despacio. Un toque de freno no
   devuelve la cámara de golpe (se ve en la serie de frenada, §6.5).
3. **El retardo de guiñada no toca la distancia**: la cámara se coloca *siempre* a la
   distancia de diseño del coche; lo único que lleva retardo es la dirección. Por eso
   en curva la distancia medida coincide con la de diseño con ±0,001 m (columna
   "diseno" de la sonda).
4. **Anticolisión mínima y filtrada**: si hay muro entre el coche y la cámara, se
   acorta la distancia a `bloqueado - 0,35 m`, nunca menos de 3,6 m, y ese acortamiento
   pasa por un filtro de 0,08 s. Además, al acortar, la cámara baja y mira más cerca
   (`squeeze`), porque acercarse sin bajar dejaba la cola del coche fuera del encuadre
   (medido: 142 px por debajo del borde con el muro de prueba) — bajar cuesta menos que
   quedarse mirando un muro.
5. **El FOV no se toca**, a propósito: subirlo con la velocidad encogería el coche
   (lo contrario de lo pedido) y bajarlo recortaría la pista por delante. El trabajo lo
   hace la distancia, que es lo que la fase pedía priorizar.

---

## 6. Resultado medido (anfitrión, lienzo 2400×1080)

Dos instrumentos independientes por caso:

* **Geométrico**: se proyecta la caja del modelo del coche con la cámara real
  (`unproject_position`). Es una **cota superior** del coche visible.
* **Píxeles**: se restan dos capturas del *mismo fotograma* con el coche visible y
  oculto (`<caso>-coche.png` y `<caso>-fondo.png`) y se cuenta la silueta. Esto se
  hace **sobre los ficheros** con `.tools/recovery/camera_pixels.py`, que no mira
  ninguna variable del juego. Es la medida que manda.

Los dos coinciden dentro del 75–87 % (columna "acuerdo" de `pixeles.json`), lo que
confirma que el crecimiento no es un artefacto de una sola forma de medir.

**La lectura de la velocidad en el dispositivo va validada contra valores conocidos.**
Sobre el teléfono no hay sonda que imprima la velocidad, así que se lee de la barra
del HUD; para que esa lectura sea un instrumento y no una suposición se prueba sobre
las capturas del anfitrión, donde la velocidad la mide la sonda por dentro: de 12
casos, el peor desvío por encima de 5 km/h es **0,7 km/h**, y a 0,7 km/h reales la
barra marca 2,0 (el redondeo del extremo de la barra; el coche no está parado, está a
0,7 km/h). La barra se lee en su fila central, porque las esquinas redondeadas hacen
que las filas de arriba y abajo midan ~11 px menos por extremo.

### 6.1 Antes y después, lado a lado

| Caso | vel. real | dist. **antes** | dist. **nueva** | alto px antes | alto px nueva | % antes | % nueva |
|---|---|---|---|---|---|---|---|
| parado | 0,7 km/h | 9,03 m | 11,39 m | 219 px | 155 px | 20,4 % | 14,4 % |
| 50 | 50,3 | 11,27 | 10,34 | 158 | 178 | 14,6 % | 16,5 % |
| 100 | 100,0 | 13,52 | 9,29 | 126 | 206 | 11,7 % | 19,1 % |
| 107 (**captura del usuario**) | 107,0 | 13,83 | 9,13 | 122 | 212 | 11,3 % | 19,6 % |
| 150 | 149,5 | 15,75 | 8,23 | 103 | 244 | 9,5 % | 22,6 % |
| 191 (**captura del usuario**) | 189,7 | 17,57 | 7,38 | 93 | 286 | 8,6 % | 26,5 % |
| 200 | 198,4 | 17,96 | 7,20 | 89 | 298 | 8,2 % | 27,6 % |

Lectura: **antes** la distancia crecía 8,9 m y el coche encogía al 40 % del tamaño
(factor 0,41); **ahora** la distancia decrece 4,2 m y el coche crece al 192 %
(factor 1,92). De 50 km/h en adelante la cámara nueva está siempre más cerca que la
anterior; parado es 2,4 m más lejos que antes, y eso es una decisión: el requisito 5
pide margen de maniobra a poca velocidad, y el precio es que parado el coche se ve
más pequeño que con la cámara vieja (155 px contra 219 px).

### 6.2 Desaceleración desde alta velocidad

Serie de frenada (la cámara tiene que alejarse **suavemente** al frenar):

| Momento | velocidad | distancia | alto en pantalla |
|---|---|---|---|
| a fondo | 198,4 km/h | 7,20 m | 27,6 % |
| frenando | 149,2 | 7,37 m | 26,6 % |
| frenando | 99,8 | 7,88 m | 23,9 % |
| frenando | 49,4 | 8,63 m | 20,9 % |
| parado | 0,7 | 11,38 m | 14,4 % |

Monótona en velocidad, apertura total 2,27 m en la frenada completa, salto máximo
0,017 m por fotograma, **0 cambios de sentido** y 0 oscilaciones. La distancia final
(11,38 m) coincide con la de parado del caso estático (11,39 m): no queda histéresis.

### 6.3 Transición y estabilidad

Para cada caso, la sonda exige que la distancia no se mueva más de 0,05 m en una
ventana de 0,4 s ya asentada (2,4 s ≈ 4,3 constantes de tiempo). Resultado de los 13
casos: asentados, con `saltos` entre 0,0002 y 0,017 m por fotograma (el tope del
diseño es 0,10 m) y 0 cambios de sentido. Los únicos tics descartados son **3 por
corrida**, y son los mismos en la medida anterior y en la nueva: son los fotogramas en
que la propia sonda escribe un PNG y el reloj del motor se atasca — es decir, es
instrumento, no juego, y se cuenta y se declara en lugar de esconderse.

### 6.4 Encuadre, pista por delante y oclusión

* **El coche nunca queda cortado**: el margen mínimo al borde más cercano es de
  307 px parado y **80 px a 200 km/h** (y 59 px en el caso del muro de prueba, que es
  el peor caso forzado). El requisito de la sonda es ≥ 20 px.
* **Pista visible por delante**: se proyectan puntos de la trazada a 20, 40 y 60 m por
  delante del coche. En los 13 casos los tres puntos caen **dentro** del cuadro y por
  delante de la cámara (nunca "detrás"). A 200 km/h caen en la mitad superior
  (y = 582/545/530 sobre 1080), que es exactamente lo que se quiere al ir cerca: mirar
  lejos.
* **Nada se interpone** entre el coche y la cámara en ninguno de los casos del
  circuito (`interpuesto: false`), y la cámara no está metida en el entorno
  (`paredes_alrededor: 0` en los casos de pista).

### 6.5 FOV

`fov: 72.0` en los 13 casos, idéntico al de la cámara anterior. El acercamiento es
distancia real, no encuadre.

---

## 7. La anticolisión, probada aunque el circuito no la necesite

El barrido del circuito (una posición cada 8 puntos de la trazada, con tres
desplazamientos laterales a la altura y a la distancia de la cámara) encuentra **0
posiciones** con algo detrás del coche donde la cámara podría quedar tapada: en
Barcelona la cámara no se mete en un muro en marcha normal. Eso significa que el
circuito no puede demostrar el guardia por sí solo, así que se prueba con un **muro de
prueba** interpuesto a 2,6 m de alto y a 6,0 m del coche:

| Medida | Valor |
|---|---|
| distancia de diseño | 9,33 m |
| distancia aplicada | **5,68 m** (acortada) |
| cámara dentro del muro | **no** |
| paredes detectadas alrededor | 2 |
| altura de la cámara con el acortamiento | 2,18 m (baja por `squeeze`) |
| margen de encuadre del coche | 59 px (sigue entero) |
| salto máximo al entrar en el guardia | 0,48 m en un tic, y es la entrada al muro de prueba |

Este es el único caso con un salto por encima del tope de 0,10 m, y es el caso
sintético en el que el muro **aparece** delante de la cámara: el filtro de 0,08 s
reparte el acortamiento. Se declara aquí en vez de esconderlo. En el circuito real
nunca se dispara (0 posiciones), así que no afecta a la conducción.

---

## 8. Rendimiento

* La cámara cuesta **O(1) por tic de física**: un producto escalar, dos exponenciales
  y **una** consulta de rayo por tic (el coche ya hace ocho entre las cuatro ruedas y
  el suelo, así que es un 12 % más de consultas). No hay asignaciones por fotograma,
  ni bucles, ni `look_at` dobles.
* **Fotogramas por segundo en la GPU del anfitrión** (`scripts/fps_probe.gd`, 600
  fotogramas tras 180 de calentamiento, 1280×720): la referencia de este proyecto
  antes de esta fase era **75,9 fps**; la medida de esta fase está en
  §9.2 (regresión), en el mismo equipo y con la misma sonda.
* En el emulador Android disponible no se puede medir fps útiles (es traducción
  OpenGL ES→Metal saturada de CPU), por eso la cifra de referencia es la del host y
  la comprobación móvil es de comportamiento, no de rendimiento.

---

## 9. Dispositivo y regresión

### 9.1 Regresión completa

`./verify.sh` en el mismo equipo y con el mismo emulador (AVD `PRO`/Pixel 9a,
`emulator-5556`, lienzo horizontal 2424×1080): **38 comprobaciones, todas en `ok`, 0
fallos obligatorios, 0 omitidas** (`resultado: OK`, código de salida 0), incluida la
sonda de la cámara nueva y la auditoría de píxeles del anfitrión, más dos comprobaciones
**obligatorias nuevas** que sólo existen en esta fase: `camara_dispositivo` (conducir con
toques reales y capturar) y `camara_pixeles` (medir esas capturas). El APK se recompiló,
se firmó, se instaló y la huella del instalado coincide byte a byte con la del compilado:

| Artefacto | Bytes | SHA-256 |
|---|---|---|
| `build/android/F1OneShot-BarcelonaMoto.apk` | 247 695 969 | `bb7d907c46a25a604f0b8b18ef7bee9a9b8b875794180f1280163eaa2b65dbc6` |
| `assets/BarcelonaMoto-Tutorial.glb` | 188 646 600 | `d9ceb75798958c8090eff9223230b9cb56b0e56e0491405b8b89c968f6fd7c06` |
| `assets/RedBull-Drive.glb` | 26 595 516 | `a1d3f7ff073bd9bb33ae6f3050b08db3c74a04e1fc0a5e3524b860a9681d0c8a` |

El circuito y el coche **no** cambian en esta fase: los SHA-256 son los de la entrega
anterior, y en `scripts/` sólo se han tocado `race.gd` (la cámara) y `camera_probe.gd`
(la sonda). El único fichero de juego modificado es `race.gd`.

### 9.2 Rendimiento, medido antes y después

| | fps del anfitrión (1280×720, 600 fotogramas) |
|---|---|
| antes de esta fase | 75,9 |
| con la cámara nueva (primera corrida) | 79,8 |
| corrida final de la fase (15 de octubre) | **76,0** |

La horquilla entre corridas (75,9 · 79,8 · 76,0, un 5 %) es la de la propia sonda; lo
que dicen las tres medidas es que **la cámara nueva no cuesta fotogramas**, como
corresponde a un cálculo O(1) y una consulta de rayo por tic.

### 9.3 Capturas en el dispositivo: se conduce con toques reales

`capturar_dispositivo.py` relanza el juego (estado conocido: coche en la salida),
conduce con **toques reales** sobre los pedales —los mismos `input swipe` sostenidos
que usa la comprobación de toque— y captura la pantalla mientras acelera y frena. La
velocidad de cada captura **no** la pone ningún reloj del anfitrión: se lee de la barra
del HUD en la propia imagen (§6), así que la tabla de abajo es lo que el juego pintó.

Tabla completa de la corrida final (16 capturas; el alto es el de la caja del coche
sobre 1080 px de lienzo, y la columna "librea" son los píxeles de azul oscuro del chasis
que identifican la mancha medida, ver §9.4):

| captura | fase | velocidad (barra del HUD) | coche en pantalla | librea |
|---|---|---|---|---|
| `disp-001..003` | reposo | 0,0 km/h | 126 px · 11,7 % del alto | 4 996 |
| `disp-004` | acelerando | 0,0 km/h | 126 px · 11,7 % | 4 996 |
| `disp-005` | acelerando | 37,7 km/h | 130 px · 12,0 % | 5 711 |
| `disp-006` | acelerando | 95,4 km/h | 152 px · 14,1 % | 7 130 |
| `disp-007` | acelerando | 156,0 km/h | 185 px · 17,1 % | 9 339 |
| `disp-008` | acelerando | 154,0 km/h | 205 px · 19,0 % | 11 996 |
| `disp-009` | acelerando | 195,7 km/h | 225 px · 20,8 % | 13 856 |
| `disp-010` | acelerando | 233,4 km/h | 247 px · 22,9 % | 16 533 |
| `disp-011` | acelerando | 261,3 km/h | 245 px · 22,7 % | 17 012 |
| `disp-012` | frenando | 252,3 km/h | 242 px · 22,4 % | 17 030 |
| `disp-013` | frenando | 144,0 km/h | 230 px · 21,3 % | 15 590 |
| `disp-014` | frenando | 7,0 km/h | 162 px · 15,0 % | 7 855 |
| `disp-015` | frenando | 0,0 km/h | 133 px · 12,3 % | 5 172 |
| `disp-016` | parado-final | 0,0 km/h | 124 px · 11,5 % | 4 617 |

* **El coche crece al acelerar**: de 126 px parado a 225 px a 195,7 km/h, factor **1,79**
  (el criterio del script es ≥ 1,45). La comparación se hace escalón a escalón de 50 km/h
  —el script elige la captura acelerando más cercana a 0, 50, 100, 150 y 200—, y los
  cuatro escalones crecen: 126 → 130 (+3,2 %) → 152 (+16,9 %) → 205 (+34,9 %) → 225 px
  (+9,8 %).
* **El coche nunca queda cortado**: margen mínimo 176 px (`disp-010`), y el criterio es
  ≥ 8 px.
* **La frenada devuelve la cámara**, y encoge en los cuatro escalones: 252,3 km/h →
  242 px, 144,0 km/h → 230 px, 7,0 km/h → 162 px, 0,0 km/h → 133 y 124 px.
* La comprobación vive en **`verify.sh` como obligatoria** (sección 9).
* **No hay ninguna captura sin librea** (`sin_semilla: []`): las 16 eligieron su mancha
  por el chasis, no por tamaño.

**Dos cosas que salieron de aquí y que no esperaba, y que van con la entrega:**

1. **El coche anda más de lo que la sonda sugería.** Con el acelerador pisado a fondo
   desde la salida, la barra del HUD llega a **261,3 km/h** en la recta principal, y la
   curva de aceleración es física (37,7 → 95,4 → 154,0 → 195,7 → 233,4 → 261,3: pasos de
   57,7 · 58,6 · 41,7 · 37,7 · 27,9 km/h, decrecientes). El «200 km/h» de la sonda del
   anfitrión es la velocidad que su lazo de control **mantiene** en ese punto, no el
   techo del coche. Consecuencia para la cámara: `camera_full_speed_mps` = 55 m/s
   (198 km/h) es el techo de la ley, así que por encima de él la distancia se queda en
   su **tope declarado** de 7,20 m. En el dispositivo, de 195,7 a 233,4 km/h el coche
   todavía crece un 10 % y de 233,4 a 261,3 encoge un 0,8 %; con la dispersión medida
   entre capturas a la misma velocidad (11 %, ver §10), el dispositivo **no resuelve**
   esa pregunta, y quien la responde es la sonda del anfitrión, donde la velocidad la
   fija el lazo de control: 189,7 km/h → 7,38 m y 198,4 km/h → 7,20 m exactos. El tope
   es a propósito —el techo de la ley, que el requisito 4 pide explícito—, no un
   descuido, y el coche se queda en su tamaño más grande (22,9 % del alto) en lugar de
   seguir creciendo.
2. **La medida de píxeles en el teléfono es una medida de tendencia.** En el aparato no
   hay fotograma sin coche, así que la silueta la saca el clasificador de librea
   (oscuro o saturado), validado contra la diferencia real en las capturas del
   anfitrión con ≤ 3,4 % de error. En el teléfono, con otro fondo y otro sombreado, el
   clasificador agrupa el cuerpo oscuro del coche y deja fuera su parte alta más clara:
   mide **~20 % menos que la diferencia de fotogramas a la misma distancia** (126 px
   parado en el aparato contra 155 px en el anfitrión con la misma ley de cámara). Por
   eso el número absoluto del teléfono no se debe comparar con el de la sonda, y sí la
   **tendencia**, que es lo que se comprueba. La comparación absoluta se hace en el
   anfitrión sobre el mismo lienzo, con el fotograma sin coche.
3. **Ningún toque puede ir a la app equivocada.** El emulador de este equipo es un
   aparato compartido: el primer intento de captura se detuvo porque otra aplicación
   estaba en primer plano y los `input swipe` habrían ido a ella. Desde entonces el
   script comprueba el **foco** con `dumpsys window` antes de arrancar y antes de cada
   pisotón, y **se para** si el primer plano no es este juego.

### 9.4 Tres defectos del instrumento, encontrados por la propia batería

Las tres veces que esta batería dijo «no» a lo largo de la fase —la tercera, el 15 de
octubre, con las ruedas traseras ya reparadas—, el que estaba mal era el **instrumento**,
y las tres se arreglaron en el instrumento —sin tocar el juego y sin relajar ningún
criterio—. Quedan aquí porque el número de una medida vale lo que valen sus herramientas:

1. **La mancha más grande no era el coche.** La medida de píxeles del dispositivo elegía
   la mancha **más grande** de la máscara «saturado u oscuro» dentro de la ventana
   inferior central. En `disp-006` (101,3 km/h, capturas del 15 de octubre a las 00:30) el
   **césped** de la izquierda encuadra como saturado y sumó **15 077 px contra los 14 945
   del coche**: la «silueta» saltó a 417 px de alto a 101 km/h y la serie de aceleración
   dejó de ser monótona, que es justo lo que la comprobación exige. Ahora la mancha se
   elige por **librea**: la que contiene más píxeles de azul oscuro del chasis
   (`b − r ≥ 22`, `b − g ≥ 10`, luminancia < 120), que es exclusivo del coche y no lo
   cumplen ni el asfalto (`b − r = 14`, también oscuro), ni el césped —claro— ni los
   bordillos rojos. La validación del clasificador contra la resta de fotogramas del
   anfitrión **no se movió** (3,4 % de peor desvío, la misma cifra que antes), porque
   allí el coche ya era la mancha mayor; y en la captura trampa la mancha elegida por
   librea mide 154 px, dentro de la serie. En la corrida final la misma trampa reaparece
   en `disp-005` (37,7 km/h: **14 008 px y 327 px de alto** frente a los 11 299 px y
   130 px del coche), así que el arreglo no está ajustado a una captura: si se volviera a
   elegir por tamaño, **la corrida final fallaría**. El respaldo (si no hay librea a la
   vista) sigue siendo la mancha mayor y se declara: `sin_semilla: []` en las 16
   capturas.
2. **Un panel cuyo paisaje nativo es `ROTATION_0`.** La comprobación `pantalla` exigía
   `ROTATION_90` o `ROTATION_270` para dar por bueno el horizontal. El AVD de esta
   corrida (`PRO`/Pixel 9a) declara `mLandscapeRotation=ROTATION_0` (y
   `mPortraitRotation=ROTATION_270`): su pantalla es horizontal de fábrica, y con el juego
   perfectamente a pantalla completa —ventana 2424×1080, los tres marcos completos, las
   dos barras del sistema ocultas en 2 de 2 estados— la comprobación daba `fallo`. Ahora
   la orientación se contrasta con **lo que el aparato declara** como paisaje, más el
   requisito de que el tamaño lógico sea más ancho que alto, y se probó que **sigue
   fallando** con volcados retorcidos: rotación 270 con paisaje nativo 0, lienzo en
   vertical, una barra de estado visible y un volcado sin declaración de paisaje fallan
   los cuatro. La corrida que encontró el defecto queda archivada, con su `pantalla` en
   `fallo`, en [`.tools/recovery/logs/bateria-1-fallo-pantalla.log`](../logs/bateria-1-fallo-pantalla.log)
   y [`.tools/recovery/integral/checks-1-fallo-pantalla.tsv`](../integral/checks-1-fallo-pantalla.tsv).
3. **Una banda de asfalto en sombra pasaba por coche.** Con las ruedas traseras
   arregladas, la batería volvió a fallar `camara_pixeles` —2 errores, los dos de la
   misma captura—: en `disp-009` (192,7 km/h) la mancha elegida no era el coche sino una
   **banda de asfalto en sombra que cruza la pista**, de 1 067 px de ancho (toda la
   ventana de búsqueda) y 187 px de alto, con **58 016 px de semilla** de azul oscuro
   —la sombra tira a azul, y con el asfalto oscuro cumple `b − r ≥ 22` y `b − g ≥ 10`—
   frente a los **12 885 del coche**. El coche estaba medido en la misma captura, en
   segunda posición, con **219 px** de alto (entre los 191 de 152 km/h y los 244 de
   229,5 km/h, que es lo que le toca), pero perdía por número de píxeles: la elección
   por librea no basta cuando el mundo también tiene azul oscuro a mansalva. Ahora se
   descartan los candidatos que **atraviesan la ventana de búsqueda**, entendido como
   tocar **dos o más** de sus cuatro bordes: la banda tocaba **tres** (abajo, izquierda
   y derecha) y el coche no toca **ninguno** en las 12 capturas del anfitrión ni en 15 de
   las 16 del teléfono; en la única en que toca uno —el coche recortado por la derecha a
   150 km/h en el anfitrión, que es la que hizo fracasar un primer intento con la regla
   «no tocar el borde»— sigue midiéndose bien, porque un objeto puede rozar un borde
   pero no estar cortado por dos a la vez. La regla sale de los bordes de `VENTANA`, que
   ya estaba declarada, y no de un umbral nuevo de color; el respaldo (si no queda
   ningún candidato que quepa entera) sigue siendo la mancha con más semilla y se
declara.

   Medido con lo que ya tenía la herramienta: la validación del clasificador contra la
   resta real de fotogramas del anfitrión sigue en **3,4 % de peor desvío, cifra por
   cifra la misma que antes del arreglo** (12 casos), y de las 16 capturas del teléfono
   **sólo cambia la elección en `disp-009`** (187 → **219 px**, ancho 1 067 → 296,
   margen al borde 6 → 206): la serie de aceleración vuelve a crecer
   (126 · 132 · 153 · 191 · 219 px) y el factor pasa de 1,48 a **1,74**, con la frenada
   intacta (243 · 232 · 163 · 134 · 128 px). La evidencia del fallo y de los dos lados
   del arreglo queda archivada en `.tools/recovery/fase-traseras/evidencia-camara/`
   (el registro que falla, el informe de la captura, y las corridas `valida` y
   `dispositivo` de antes y después); la captura con las dos manchas marcadas está en
   [`diag-disp009.html`](../fase-traseras/diag/diag-disp009.html).

---

## 10. Limitaciones y notas honestas

* **La medida del dispositivo tiene una dispersión del 11 % a la misma velocidad.**
  `disp-007` y `disp-008` son dos capturas consecutivas con la barra en 156,0 y 154,0
  km/h —1 px ≈ 1 km/h de resolución— y el alto medido difiere un 11 % (185 frente a 205
  px). Las dos lecturas de la barra son tramos **continuos** de 157 y 155 px, comprobados
  píxel a píxel, así que no es el lector; parado, las tres capturas dan 126/126/126 px
  (0 % de dispersión). Queda declarado y **no atribuido con certeza** —el candidato
  medible es la actitud del coche bajo el pisotón, porque la suspensión es dinámica, y no
  se puede separar de un fotograma compuesto con capas de instantes distintos, que es una
  limitación conocida de este emulador—. Por eso la comprobación compara **una captura
  por escalón de 50 km/h** y lo que afirma es la **tendencia**; el número absoluto se mide
  en el anfitrión con la resta de fotogramas, donde la velocidad la fija el lazo de
  control.
* **El lienzo de la corrida final es 2424×1080** (AVD `PRO`/Pixel 9a), no 2400×1080 como
  la del 13 de octubre: la batería deriva la geometría del aparato y las dos medidas son
  comparables porque las dos tienen 1080 de alto, que es con lo que escala el HUD. Las
  capturas del retest de la fase 3 que siguen archivadas en `shots/` son 2400×1080, y en
  `handoff-evidence.json` se declaran los dos lienzos medidos (`lienzos_medidos`).

* **Parado la cámara está más lejos que antes** (11,4 m contra 9,0 m) y el coche se ve
  más pequeño (155 px contra 219 px). Es la consecuencia de pedir margen de maniobra a
  poca velocidad; de 50 km/h en adelante la cámara nueva está siempre más cerca que la
  anterior. Si se prefiere el coche grande también parado, `camera_distance_stopped_m`
  es un parámetro exportado y se cambia en un sitio.
* **La velocidad del caso "200" no es el techo del coche**: la sonda prepara el caso a
  200 km/h y mide los 198,4 que su propio lazo de control mantiene; pero con el
  acelerador pisado a fondo el coche llega a **261,3 km/h** en la recta principal
  (medido en el dispositivo, §9.3). El tope de la ley de la cámara (198 km/h) es, por
  tanto, una decisión declarada y no el máximo del coche: por encima de él la distancia
  se queda en 7,20 m.
* **La cota geométrica es una cota superior**: la caja del modelo incluye el hueco
  entre ruedas y alerones. La medida que manda es la de píxeles (resta de capturas).
  Ambas coinciden al 75–87 %.
* **La elección de la mancha sigue siendo una heurística, ahora con dos filtros.** El
  coche se identifica por librea **y** por no atravesar la ventana de búsqueda; las dos
  cosas están medidas contra la resta real de fotogramas en el anfitrión (3,4 % de peor
  desvío) y sobre 16 capturas del teléfono, pero un fondo nuevo —otra pista, otra hora
  del día, otra sombra— podría volver a colar una mancha que no sea el coche. Lo que
  protege del caso silencioso es que cada captura declara su `semilla_px` y que la lista
  `sin_semilla` tiene que ir vacía: una captura medida sin librea se cuenta y se ve en el
  informe, no pasa por buena.
* **Los 3 tics estancados por corrida** son el coste de capturar PNG desde dentro del
  juego (el reloj del motor se atasca al escribir). Aparecen igual en la medida
  anterior, se excluyen del análisis de transición y se cuentan aquí.
* **El guardia anticolisión no lo ejerce este circuito**: 0 posiciones con muro detrás
  del coche. Se prueba con un muro sintético y se documenta el único salto > 0,10 m
  que produce.
* El **dispositivo** disponible es un emulador: sirve para comprobar comportamiento y
  encuadre a distintas velocidades, no para afirmar rendimiento de un teléfono real.

---

## 11. Cómo se reproduce

```bash
# Cámara nueva: mide, dibuja las capturas y verifica los criterios (falla si no se cumplen)
./.tools/godot/Godot.app/Contents/MacOS/Godot --path . --script scripts/camera_probe.gd

# Cámara anterior, con el mismo instrumento (confirma la causa)
./.tools/godot/Godot.app/Contents/MacOS/Godot --path . --script scripts/camera_probe.gd -- legacy

# Medida en píxeles sobre los PNG (independiente del juego). Tres modos:
#   medida      resta el fotograma con coche y sin coche (anfitrión)
#   valida      contraste clasificador contra resta, para saber cuánto miente
#   dispositivo lee las capturas del teléfono y la barra del HUD
python3 .tools/recovery/camera_pixels.py medida .tools/recovery/fase-camara
python3 .tools/recovery/camera_pixels.py valida .tools/recovery/fase-camara
python3 .tools/recovery/camera_pixels.py dispositivo .tools/recovery/integral/shots/camara

# Galería comparativa antes/después
python3 .tools/recovery/fase-camara/galeria.py
```

Artefactos: `medidas.json` y `pixeles.json` de esta carpeta (nuevos) y de `antes/`
(viejos), las capturas `capturas/` y `antes/capturas/`, y la galería
`comparativa.html`.
