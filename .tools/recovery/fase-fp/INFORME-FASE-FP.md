# Fase: cámara del morro (segunda vista jugable) y su botón

Segunda cámara jugable en primera persona, en el morro del Red Bull, con un botón
de HUD para alternar con la cámara de persecución **sin detener la carrera**.

Toda la fase se apoya en medidas sobre el juego real. Los números que hay aquí
salen de las sondas y de los PNG que dejan en disco; ninguno está estimado a ojo.

---

## 1. Auditoría previa (lo que ya existía)

| Pieza | Dónde | Qué se encontró |
|---|---|---|
| Cámara de persecución | `race.camera`, resuelta en `_update_chase_camera` | Distancia dinámica (11,4 m parado → 7,2 m a tope), altura, adelanto del punto de mira, retardo de guiñada y anticolisión de muro. Fase anterior cerrada y medida. |
| Cámara (nueva) | `race.nose_camera` | No existía. |
| Modelo del coche | `assets/RedBull.tscn` → `gltf_model.gd` → `RedBull-Drive.glb`, hijo del `CharacterBody3D` | Su transformación es la del coche: hacia delante es **−Z**. |
| Morro / neumáticos | Medidos en el marco del coche | eje delantero **z = −1,511 m**; alto del neumático delantero **y = +0,748 m** (radio 0,374); punta del alerón z = −2,763 m; techo de la carrocería y = +1,232 m. |
| HUD | `scripts/race_hud.gd` (CanvasLayer) | Telemetría arriba a la izquierda, cronómetro arriba al centro, mando abajo a la izquierda, pedales abajo a la derecha. No había botón de vista. |
| Controles | `scripts/touch_controls.gd` | Multitáctil independiente por puntero; regiones publicadas en `.tools/recovery/screen_geometry.py`, que es también quien dice al inyector de toques del teléfono dónde pisar. |

**Dos medidas malas que se encontraron y se corrigieron por el camino** (las dos
daban un resultado *creíble* y equivocado):

1. La primera medida del alto del neumático usaba las esquinas de la caja de la
   rueda **a través del giro de la rueda**: una caja girada proyecta otra caja, así
   que el alto salía distinto en cada vuelta (0,748 m con la rueda en cruz y
   0,52 m a 45°). Se mide por el **buje** (origen del nodo, no gira) más el radio
   de la malla (tampoco gira) → invariante.
2. La composición *no* se puede juzgar proyectando vértices: la cámara del morro
   queda a 12 cm del carenado y los vértices pegados al plano cercano proyectan
   una caja de **21 anchos de lienzo** con el encuadre perfectamente correcto
   (medido, con la primera versión de la sonda dando "el coche ocupa el 73 % de la
   franja" sobre una captura que se veía bien). Se mide en **píxeles**.

---

## 2. Dónde está la cámara y por qué ahí

El punto de vista no se inventa: sale de los hitos medidos del modelo.

```
z de la cámara = eje delantero        + nose_behind_axle_m   = −1,511 + 0,30 = −1,211 m
y de la cámara = alto del neumático   + nose_above_wheels_m  =  0,748 + 0,26 =  1,011 m
x de la cámara = 0 (centro del coche)
inclinación hacia abajo = 17°     campo de visión = 74°
```

- **Detrás del eje delantero** (0,30 m) para que los neumáticos queden *delante* y
  se vean a los lados, como en la referencia aprobada. Sobre el eje quedarían
  cortados por el borde inferior.
- **Por encima del alto del neumático** (0,26 m) para quedar **fuera del
  carenado** en su vertical. Medido contra el perfil real de la malla del chasis:
  techo de la carrocería en z = −1,211 → **0,786 m** ⇒ holgura **0,225 m**.
- **17° hacia abajo**: sube el morro a la franja inferior y deja el horizonte al
  27 % del alto (la referencia aprobada lo tiene en ~23 %).
- **74°**: el coche ocupa el 34 % del alto por abajo y la pista se ve de cerca a
  lo lejos (los cinco puntos de trazada medidos a 20/40/60/100/150 m caen dentro
  del cuadro).

Son parámetros declarados y ajustables en `race.gd` (`@export_category("Nose
camera")`), no constantes escondidas en el cuerpo de una función.

---

## 3. Composición medida en píxeles contra la referencia aprobada

La sonda deja por cada caso **cinco** capturas del mismo instante (el reloj se
congela durante las capturas: sin eso el coche avanza metros entre una y otra y
la diferencia mide paisaje, no coche):

- `composicion-<caso>-todo.png` — el coche entero visible
- `composicion-<caso>-sin-coche.png` / `-sin-delanteras.png` — diferencia de fotogramas
- `composicion-<caso>-coche-magenta.png` / `-delanteras-cian.png` — segmentación pintada

La medida que **decide** es la pintada (recorte por color, exacto). La de
diferencia se informa al lado como contraste: se queda corta donde el asfalto es
tan oscuro como el neumático (5.083 px a 150 km/h frente a 28.098 a 100 km/h con
la misma cámara), y por eso no decide.

Composición final (lienzo 2400×1080, `morro.json` y `morro-pixeles.json`):

| Caso | km/h | franja del coche | centro x | neumático izq. | neumático der. |
|---|---|---|---|---|---|
| parado | 0 | 0,34 | 0,50 | 37.538 px | 29.793 px |
| recta | 99 | 0,34 | 0,50 | 37.265 px | 30.354 px |
| recta | 149 | 0,34 | 0,50 | 25.020 px | 17.255 px |
| recta | 195 | 0,34 | 0,50 | 37.846 px | 29.766 px |
| curva | 121 | 0,32 | 0,50 | 35.876 px | 27.635 px |
| frenada | 60 | 0,33 | 0,50 | 26.038 px | 15.229 px |

Referencia aprobada, medida con la regla declarada en `morro_pixeles.py` (librea
azul oscura o negro neutro de neumático, mancha contigua al borde inferior):
**franja del coche 0,43**, centro x 0,50. El juego cae dentro de la ventana
(±0,18) y su franja **no cambia con la velocidad**: 0,33–0,34 en las seis
situaciones.

La fila de «curva» está actualizada a la última pasada (la de la fase de los muros
invisibles); las otras cinco son de la pasada de esta fase.

El caso «curva» cambió en la fase de los muros invisibles de la calzada. Antes
sostenía 130 km/h en el viraje más cerrado del trazado (radio 30 m, ~3,8 g de agarre
lateral) y sólo quedaba dentro de la pista porque lo detenía el relieve invisible que
esa fase hundió; sin él, el coche se iba fuera y su silueta acababa dentro de la
barrera. El escenario final es el viraje **más cerrado que el coche puede tomar a**
**130 km/h** con un límite de agarre declarado (0,9 g), con el asentamiento colocado
para terminar dentro del viraje, y el caso exige que el coche siga sobre la calzada y
a ≤4 m de la trazada: medido **conduciendo**, 121,1 km/h por el viraje de radio 148 m,
0,27 g pedidos, 0,27 m de la trazada y sobre `TRM-BRC`. Con el relieve ya hundido se
probó antes a la velocidad que permite el viraje de radio 30 m (41 km/h) y ahí salió
el segundo problema: con la dirección tan girada uno de los neumáticos delanteros
queda tapado por la carrocería (medido: 9 269 px, 0,36 % del lienzo, por debajo del
0,5 % que pide el caso).

Las **fotografías** de la composición en la curva se toman con el coche DETENIDO en el
mismo punto del viraje, y el motivo también está medido: a velocidad, cuánto neumático
delantero enseña la cámara no es reproducible —el mismo neumático sale con 51 377 px
en una pasada y con 10 049 px en otra, en el mismo viraje y a la misma velocidad, con
la suspensión dentro de su recorrido (±0,7 mm), sin topar y con 0,03° de dirección—
mientras que la composición no depende de eso, porque la cámara es rígida respecto al
coche (0,0000 m de deriva en las seis situaciones). Detenido en el mismo punto del
viraje el estado sí es reproducible (es el de la sonda «parado», repetible al 2 %).

Y la silueta se mide con **una sola regla en las seis situaciones**: el color plano
con el que la sonda pinta el coche. Mientras las fotografías de la curva se tomaban
rodando, esa captura traía además una banda magenta sobre lo que el fotograma normal
dibuja como cielo (medido: la fila 200, columna 1200 salía (255, 0, 255) contra
(151, 187, 205)) y la franja pintada salía 0,87 frente a 0,32 por diferencia, así que
en la curva decidía la diferencia. Con la fotografía detenida la banda no aparece y
las dos reglas dan la **misma** franja y el mismo borde superior en las seis (difieren
0,0000; 0,316–0,336 con y0 en 717–739). El medidor calcula las dos y ahora **exige que
coincidan** (se admite 0,05): si la captura pintada vuelve a traer algo que no es el
coche, la comprobación lo dice en vez de cambiar de regla. Ver
`.tools/recovery/fase-muros/INFORME-FASE-MUROS.md`, sección 5.

Comparación de encuadre con la referencia: en el juego los neumáticos se quedan en
los cuartos laterales —borde **interno** a 0,25 del ancho el izquierdo a parado, 100,
200 km/h y en la curva, y 0,17–0,18 a 150 km/h y en la frenada; el derecho a 0,76 del
ancho (0,84 a 150 km/h y en la frenada)— mientras que en la referencia llegan al
centro del cuadro (0,50), porque el coche de la referencia lo llena más (franja 0,43
frente a 0,32–0,34 del juego).

---

## 4. El botón de cambio de vista

- Vive en `race_hud.gd`, arriba a la **derecha** (la única esquina libre), anclado
  al borde derecho con 24 px de margen, 196×52 px a escala 1,0, y dice en todo
  momento qué cámara está puesta (`CÁMARA · PERSECUCIÓN` / `CÁMARA · MORRO`).
- Comprobado con los rectángulos **reales** de los controles, no con una copia:
  botón (2136, 24, 236×62) frente a telemetría (29, 24, 434×178), cronómetro
  (1002, 24, 396×170), mando (58, 767, 257×257), acelerador (2231, 810, 114×230)
  y freno (2054, 810, 114×230): **cero solape**.
- Su región está en `.tools/recovery/screen_geometry.py` (`camara_boton`,
  `camara_boton_centro`), que es quien coloca el dedo del inyector en el teléfono:
  el punto que se pisa sale de la geometría del lienzo, no de números a mano.

---

## 5. Cambio de vista, y por qué la carrera no se detiene

- La cámara que **entra** arranca exactamente donde estaba la que **sale**, así
  que el corte es invisible: medido, la primera muestra nace a 0,071 m y 0,082 m
  (el primer paso del arco, a 120 Hz).
- Llega a su sitio en 0,22 s describiendo un arco por encima del coche (el camino
  recto pasa por dentro de la carrocería).
- **Holgura mínima durante el cambio**: 0,225 m y 0,269 m. Aquí se corrigió un
  fallo real: el arco se medía con el avance *suavizado* (`smoothstep`), que al
  15 % del cambio sólo ha subido el 6 % de la altura, y la cámara pasaba por
  encima de la toma de aire **2 cm por dentro** de la carrocería (holgura −0,019 m
  en el fotograma 2 de la vuelta a la persecución). Con el progreso **lineal** del
  arco, la subida llega antes de que la cámara esté sobre el carenado.
- La carrera sigue: el cronómetro es monótono y avanza durante el cambio, el
  número de vueltas no cambia, y el coche avanza lo que le toca a su velocidad
  (25,1 m en los fotogramas de física que dura el cambio, a 160 km/h).
- Las dos cámaras conservan su comportamiento: la persecución **sigue calculando**
  su estado en segundo plano (al volver, su distancia es la de diseño ±0,5 m) y su
  distancia dinámica y su anticolisión **no tocan** la cámara del morro.

---

## 6. Compatibilidad con la cámara dinámica (el punto que pedía la fase 4 del encargo)

La primera persona es **rígida respecto al coche**: el desplazamiento se construye
en el marco del coche (no en el del mundo) y sólo hereda los giros del chasis
(cabeceo y balanceo de la suspensión). Medido en las seis situaciones, de parado a
195 km/h: deriva máxima respecto a su punto de vista **0,0001 m**, salto máximo por
fotograma **0,0001 m**. No se aleja al correr, y no se tocó la física del coche ni
la suspensión para conseguirlo.

---

## 7. Validación

### Anfitrión (dos comprobaciones nuevas en `./verify.sh`)

| id | qué mide |
|---|---|
| `sonda_morro` | `scripts/camera_nose_probe.gd`: composición geométrica, pista visible, horizonte, holgura contra el perfil real del chasis, rigidez, y el cambio de vista en los dos sentidos con el cronómetro y las vueltas. |
| `audit_morro` | `.tools/recovery/fase-fp/morro_pixeles.py`: composición **en píxeles** contra la referencia aprobada. |

### Dispositivo (una comprobación nueva, con toques reales)

| id | qué mide |
|---|---|
| `morro_dispositivo` | `.tools/recovery/fase-fp/capturar_morro_dispositivo.py`: relanza el juego, acelera con pisotones reales del pedal, **pisa el botón con un `input tap` real** en su centro, y mide las capturas con dos señales estructurales (fracción de píxeles saturados en la caja inferior central y altura del horizonte). Comprueba además que el coche **sigue moviéndose** en las cuatro capturas y que el cronómetro avanza alrededor del cambio. |

Medidas del dispositivo (lienzo 2424×1080, emulador `emulator-5556`):

| Captura | km/h | saturado en la caja inferior central | horizonte | vista |
|---|---|---|---|---|
| persecución (ida) | 244 | 0,007 | 0,285 | CÁMARA · PERSECUCIÓN |
| **morro** | 194 | **0,419** | **0,111** | CÁMARA · MORRO |
| persecución (vuelta) | 164 | 0,004 | 0,306 | CÁMARA · PERSECUCIÓN |
| persecución con el pedal pisado | 197 | 0,028 | 0,178 | CÁMARA · PERSECUCIÓN |

- El cronómetro pasó de `00:08.242` a `00:15.667` a lo largo de la secuencia
  (969 px cambiados en su región del HUD, 238 de contraste máximo): **la carrera
  no se detuvo ni se reinició**.
- La última captura es con el acelerador pisado después del cambio y el coche
  **subiendo** (164 → 197 km/h): los pedales siguen respondiendo.

### APK

- `build/android/F1OneShot-BarcelonaMoto.apk`, exportado con el preset del
  proyecto, firmado e instalado en el emulador.
- SHA-256 del APK instalado y verificado por `./verify.sh`: ver el informe
  integral (`.tools/recovery/integral/verificacion-integral.json`) y
  `.tools/recovery/fase-fp/entrega.json`.

---

## 8. Archivos de esta fase

- `scripts/race.gd` — cámara del morro (`@export_category("Nose camera")`),
  medición del anclaje sobre el modelo, cambio de vista con arco y transición.
- `scripts/race_hud.gd` — botón `Camera switch` y su anclaje al borde derecho.
- `scripts/camera_nose_probe.gd` — sonda del anfitrión (nueva).
- `.tools/recovery/fase-fp/morro_pixeles.py` — composición en píxeles (nueva).
- `.tools/recovery/fase-fp/capturar_morro_dispositivo.py` — cambio de vista con
  toques reales en el dispositivo (nueva).
- `.tools/recovery/fase-fp/geometria_modelo.gd` — hitos medidos del modelo.
- `.tools/recovery/fase-fp/hoja_de_contacto.py` + `hoja-de-contacto.html` — hoja
  de contacto autocontenida con las capturas y las máscaras.
- `.tools/recovery/fase-fp/referencia.png` — la referencia visual aprobada, dentro
  del repositorio para que la comparación sea reproducible.
- `.tools/recovery/screen_geometry.py` — región del botón para el inyector de toques.
- `verify.sh` — `sonda_morro`, `audit_morro` y `morro_dispositivo`.

## 9. Límites conocidos (lo que esta fase NO deja demostrado)

- La **visibilidad del neumático depende del giro de la dirección**: con las
  ruedas giradas el neumático que gira "de cara" enseña mucho más flanco que el
  otro (medido: 25.807 px frente a 15.465 px en la frenada). Los dos se ven
  siempre —es lo que exige el criterio— pero la simetría perfecta de la referencia
  no se da en todas las situaciones.
- El horizonte **se tumba** con el balanceo del chasis en curva (como una cámara
  montada en el morro de verdad). No se corrige: corregirlo sería alterar la
  actitud del coche para un efecto visual, que es justo lo que el encargo prohíbe.
- Las medidas del cambio de vista en el anfitrión están tomadas a 160 km/h sobre
  la recta. Fuera de ahí (muros pegados) la anticolisión de la *persecución*
  puede acortar su recorrido, y el arco del cambio se mide con la cámara entrante;
  no se ha muestreado el cambio contra un muro.
