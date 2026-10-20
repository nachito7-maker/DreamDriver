# Integrar la línea de asistencia en el asfalto: pintura mate, discreta y desgastada

Fase visual sobre el estado actual del proyecto (`F1 One Shot Barcelona Moto`, Godot 4.7.2
para Android). La recomendación de conducción —colores, bandas, envolventes, antelación,
velocidad ideal— **no se ha tocado**: sólo cambia el aspecto con el que se pinta.

---

## 1. Sistema que dibuja la línea

`scripts/driving_line.gd` es un `MeshInstance3D` con un `ArrayMesh` propio —un listón de
dos vértices por punto de la trazada (3057 anillos, 1,51 m de paso), con la longitud de
arco en la `UV.x`— y un `ShaderMaterial` con el shader **en línea dentro del script** (para
que viaje con él en el APK). No usa textura de imagen ni emisión: el estado de cada tramo
(color de acelerar/levantar/frenar) va en una **textura de estado de 4096×1** que se
reescribe cada fotograma (los ~230 texeles de la ventana visible), y el shader lee ahí el
color del fragmento según su arco.

Antes de esta fase, el fragmento hacía:

```glsl
render_mode unshaded, cull_disabled, depth_draw_opaque;
...
float edge = smoothstep(0.0, u_edge_blend, UV.y) * smoothstep(1.0, 1.0 - u_edge_blend, UV.y);
ALBEDO = mix(u_rubber, action, edge);     // opaco, sin luz, borde casi recto
```

Es decir: **color plano sin iluminación** (`unshaded`), opaco, con un borde de fusión del
35 % y corte en seco de la ventana dibujada (260 m por delante, 3 m por detrás). El
aspecto de «superposición gráfica» venía de ahí: la pintura no recibía la luz de la
escena, era un color saturado escrito directamente en pantalla y su canto terminaba en una
recta.

Dónde estaba cada cosa (y dónde está ahora) es todo en `driving_line.gd`: ancho
(`line_half_width_m`), altura sobre el asfalto (`line_lift_m`), colores
(`color_accelerate/hold/brake/rubber`), fusión del borde (`color_edge_blend`), la ventana
visible (`visible_window_m`, `visible_tail_m`) y el sesgo de profundidad por distancia
(`depth_bias_per_m`, que sigue igual: es el que evita el z-fighting).

---

## 2. Archivos modificados y por qué

| archivo | cambio | motivo |
|---|---|---|
| `scripts/driving_line.gd` | shader: fuera `unshaded`; `ROUGHNESS 1,0`, `SPECULAR 0,15`, `METALLIC 0`; borde con fusión **ondulada**; **desgaste** por arco; **fundido** con la calzada al final de la ventana y detrás del coche | la pintura tiene que recibir la luz de la calzada, ser mate y fundirse en la superficie en vez de ser una capa de color |
| `scripts/driving_line.gd` | ancho 0,56 → **0,46 m**; altura 0,02 → **0,015 m** | menos superficie de calzada y más cerca del asfalto |
| `scripts/driving_line.gd` | paleta nueva (albedo) y fusión del borde 0,35 → **0,22**; desgaste 0,35; fundido 40 m | colores apagados elegidos **por el color que sale en pantalla** (ver §3) y núcleo de pintura sólido suficiente para que la auditoría de píxeles siga midiendo |
| `.tools/recovery/linea/linea_pixeles.py` | `ANCHO_LINEA_M` 0,56 → 0,46 y su comentario | es la anchura **declarada** en el script; el tope `ancho ≤ 1,3 × declarado` sigue siendo el mismo criterio (más estricto que antes, porque 1,3 × 0,46 < 1,3 × 0,56) |
| `.tools/recovery/linea/capturar.gd` | un comentario (0,56 → 0,46) | coherencia con la anchura declarada |
| `.tools/recovery/linea-visual/` (nuevo) | `calibrar.gd` + `calibrar.py`, `comparar.py`, `contraste_por_estacion.py` y sus resultados | medir el color **pintado** (no el escrito), comparar antes/después y saber cuánto contraste hace falta estación a estación |

No se ha tocado nada de la lógica: `verdict`, las envolventes, la velocidad ideal, el
perfil de colores de la textura de estado, la geometría de la trazada ni el control del
coche. La sonda funcional sigue midiendo lo mismo y pasa igual (§5).

---

## 3. Valores visuales: antes y nuevo

### 3.1 Lo que se escribe en el archivo (albedo sRGB)

| | antes | ahora |
|---|---|---|
| verde (acelerar) | `Color(0.20, 0.55, 0.27)` | `Color(0.34, 0.45, 0.33)` |
| amarillo (levantar) | `Color(0.87, 0.68, 0.18)` | `Color(0.54, 0.48, 0.32)` |
| rojo (frenar) | `Color(0.74, 0.16, 0.13)` | `Color(0.53, 0.39, 0.33)` |
| goma (borde/fundido) | `Color(0.30, 0.30, 0.30)` | `Color(0.63, 0.63, 0.63)` |
| material | `unshaded` (sin luz) | difuso, `ROUGHNESS 1.0`, `SPECULAR 0.15`, `METALLIC 0`, sin emisión |

El gris de la goma **no es un adorno**: es el color con el que el borde de la pintura se
funde y con el que la línea se disuelve en el horizonte. Se eligió midiendo: `(0.63, 0.63,
0.63)` es el albedo que pinta en pantalla el **mismo gris que la calzada** que rodea la
línea, así que el borde y el fundido desaparecen en la superficie en vez de dejar un canto.

### 3.2 Lo que se pinta en pantalla (medido, misma pose y misma luz)

Media de las muestras pautadas, tal y como las mide la sonda de captura (§4). Caso
`recta` (recta de salida a 300 km/h; asfalto al lado `(160, 166, 175)`):

| estado | antes | ahora | cromaticidad antes → ahora | pico de canal antes → ahora |
|---|---|---|---|---|
| verde | (18, 83, 27) | (65, 93, 67) | 0,25 → 0,11 | 83 → 93 |
| amarillo | (188, 126, 17) | (121, 101, 65) | 0,67 → 0,22 | 188 → 121 |
| rojo | (146, 17, 17) | (117, 77, 67) | 0,51 → 0,20 | 146 → 117 |
| **peor de los tres** | **0,67** | **0,22** | | **188 → 121** |

Y en la pose de frenada (`frenada`), que es la más oscura de las cuatro: antes `(18, 89,
28)`, `(201, 135, 18)`, `(157, 17, 18)` con cromaticidad **0,72** y pico **201**; ahora
`(40, 73, 40)`, `(109, 84, 39)`, `(104, 55, 40)` con cromaticidad **0,27** y pico **109**.

Lo que dicen estos números:

* **La saturación baja a un tercio.** La «cromaticidad» es (máx − mín)/255, exactamente lo
  que audita `linea_pixeles.py`; el tope declarado es 0,78 y la pintura anterior llegaba a
  0,72 (al borde). Ahora se queda en 0,22–0,27.
* **Ningún canal se apaga.** Antes el verde era (18, 83, 27) y el rojo (146, 17, 17): rojo
  y azul prácticamente a cero, que es la firma del «led» de videojuego (ninguna superficie
  real refleja cero rojo y cero azul). Ahora los tres canales están siempre presentes
  (mínimos 39–65 en la pose de frenada), que es lo que hace que se lea como pintura sucia.
* **Ya no es lo más brillante de la escena.** El pico de canal pasa de 201 a 109–134: la
  línea es **más oscura** que el asfalto que la rodea, no más brillante.
* **Los tres estados siguen distinguiéndose.** La distancia ponderada entre los dos
  estados más parecidos (la que exige ≥ 45) pasa de 133 a 68–150 según la pose, siempre por
  encima del criterio; y en cada muestra pautada el color pintado es el que la línea dice
  (100 % de aciertos en las cuatro poses, §5).

### 3.3 Geometría, borde y comportamiento por distancia

| | antes | ahora |
|---|---|---|
| ancho declarado | 0,56 m | 0,46 m |
| ancho medido en píxeles (cortes pautados) | 0,50 m | 0,40 m |
| altura sobre el asfalto | 0,020 m | 0,015 m |
| transición del canto | **< 0,10 m** (borde de un píxel: ningún corte tiene pintura a medias) | **0,10–0,20 m** (el canto se funde con la goma en 1–2 muestras de 0,1 m) |
| desgaste | ninguno | dos ondas lentas por longitud de arco (periodos ~150 m y ~55 m): ensanchan la fusión del borde y dejan zonas con menos pintura. Son función del arco, **no del tiempo**: no parpadean |
| fin de la ventana | corte en seco (`discard`) a 260 m y a 3 m por detrás | **fundido de 40 m** hacia el gris de la calzada hasta 260 m, y fundido también en el tramo de cola (detrás del coche) |
| iluminación | ninguna (`unshaded`) | la de la escena: la pintura se oscurece en sombra y con el sol, igual que la calzada |

El ancho de transición se mide sobre los cortes transversales de la sonda (una muestra cada
0,1 m): con el borde de antes **ninguna** muestra caía a medio camino entre el asfalto y la
pintura —un canto de un píxel, el de una pegatina—; con el de ahora hay 1–2 muestras por
lado a medio camino. Es la diferencia medible entre un canto recortado y una pintura que se
despega y se gasta.

---

## 4. Capturas del antes y del después

Las capturas las hace `.tools/recovery/linea/capturar.gd` con la escena de carrera real
(lienzo 2400×1080, cámara de persecución, luz y tonemap del juego). Por cada caso guarda el
mismo instante con la línea y sin ella, más la misma pose con la línea forzada a cada uno
de los tres colores; la comparación de las dos versiones del código usa **la misma pose, la
misma cámara y la misma luz** porque la búsqueda de casos es determinista.

* `.tools/recovery/linea-visual/comparativa.html` — la hoja con los recortes de antes y de
  después (calzada cerca del coche y línea a 100–180 m) y las tablas de medidas.
* `.tools/recovery/linea-visual/comparativa-<caso>.png` — cada comparación por separado.
* `.tools/recovery/linea-visual/antes/` — las capturas de la pintura anterior completas
  (PNG + `capturas.json` + la copia de `driving_line.gd`), que es el «antes» de referencia.
* `.tools/recovery/linea/disparos/` — las capturas de la pintura nueva.
* `.tools/recovery/linea-visual/galeria-dispositivo.html` — la galería de las capturas del
  **dispositivo** (persecución conduciendo con toques reales y cámara de morro), más las cuatro
  hojas de comparación del anfitrión. La genera
  `.tools/recovery/linea-visual/galeria_dispositivo.py` y es lo que hay en el panel derecho:
  van **incrustadas y reducidas a 1000 px** (JPEG sin submuestreo de color) porque el panel
  sirve el documento y sólo el documento; los originales son los de las carpetas de arriba y
  las medidas se hacen sobre ellos.

Situaciones cubiertas con el mismo encuadre (el «antes» y el «después» de cada una):

| lo que pide el encargo | caso | encuadre |
|---|---|---|
| recta con recomendación verde | `recta` (índice 0, 300 km/h) | cámara de persecución |
| aproximación a una frenada (amarillo) | `aproximacion` (índice 310) | cámara de persecución |
| zona de frenada roja | `frenada` (índice 420) | cámara de persecución |
| salida de curva, verde por delante | `salida` (índice 2910) | cámara de persecución (otra estación: el patrón se cumple en varias, se indica) |
| vista cercana del asfalto y la pintura | recorte 2× del campo cercano | mismo encuadre |
| la línea a distancia | recorte 3× de las estaciones de 100–180 m | mismo encuadre |
| cámara de morro y cámara exterior | capturas del dispositivo (§8) | morro y persecución |

En cada recorte se ve la pintura nueva sin dominar la calzada: sin canto recto, sin brillo,
sin color puro y con la textura del asfalto a la vista por los dos lados (el listón ocupa
0,40 m medidos, dentro de una calzada de más de 10 m).

**Qué curva es cada pose, medido.** Los casos no se eligen por el tipo de curva sino por el
patrón de la recomendación, así que la etiqueta de «curva lenta» y «curva rápida» hay que
sacarla de la geometría. `.tools/recovery/linea-visual/curvatura_casos.gd` (sonda sin GPU,
`"$GODOT" --headless --path . --script .tools/recovery/linea-visual/curvatura_casos.gd`)
imprime el radio de la trazada en el índice exacto de cada caso y la velocidad ideal de la
línea:

| caso | índice | radio de la trazada | ideal en el punto | ideal mínima en los 260 m visibles | lectura |
|---|---|---|---|---|---|
| `recta` | 0 | 4.013 m | 360 km/h | 360 km/h | recta pura |
| `aproximacion` | 310 | 3.833 m | 360 km/h | **341 km/h** | recta con el aviso ya encendido: la frenada está más allá de la ventana |
| `frenada` | 420 | 2.786 m | 360 km/h | **84 km/h** | frenando hacia una curva lenta: el rojo está encendido y el vértice (84 km/h de ideal) se ve al fondo de la ventana |
| `salida` | 2910 | **142 m** | 138 km/h | 138 km/h | curva de radio medio en su salida (105° de giro dentro de la ventana): la línea se ve doblarse en el encuadre |

De ahí la cobertura de lo que pide el encargo: la **curva lenta** está en `frenada` (frenando
hacia un vértice de 84 km/h de ideal, al fondo del encuadre) y en `salida` (142 m de radio con
la pintura doblando en pantalla), y la **curva rápida** es, en la cámara real, indistinguible de
una recta: en las poses de 2.786-4.013 m de radio la línea gira 5,3° en los 260 m de ventana
frente a los 105° de la de 142 m, y por eso las cubren `recta` y `aproximacion` (ideal ≥
341 km/h). Un caso capturado
dentro de una curva rápida a alta velocidad no aportaría nada que no esté ya en esas dos, y no
se ha añadido: lo que la pintura hace distinto en curva —doblar y seguir la trazada— ya se mide
en `salida` y en la auditoría de geometría del listón (§5).

Aviso sobre las fichas de captura: en `capturas.json` los cuatro casos figuran a **300 km/h**,
que es la velocidad de referencia con la que se evalúa la recomendación para escoger la pose
(el coche de la captura está quieto, es un encuadre fijo), no la velocidad del coche en ese
fotograma.

---

## 5. Pruebas y comprobaciones

Todas las órdenes se han ejecutado tal cual (sin relajar ningún criterio).

| comprobación | antes | ahora |
|---|---|---|
| `sonda_linea` (`driving_line_probe.gd`, headless, 44 comprobaciones: velocidad ideal, envolventes, punto de frenada, monotonía, vuelta conducida con la línea, geometría del listón) | 44/44 ok | **44/44 ok** |
| `capturar_linea` (4 casos, la línea y la goma, en GPU) | ok | **ok** |
| `audit_linea` (`linea_pixeles.py`, 24 comprobaciones en píxeles) | 24/24 ok | **24/24 ok** |
| `linea_dispositivo` (en el aparato) | verde ok / calzada azulada **fallo** | **ok** (14/14 capturas con pintura, calzada 4/255 de azul) — ver §8 |
| `./verify.sh` completo | 51 `ok` / 3 `fallo` (`toque`, `camara_pixeles`, `linea_dispositivo`) | 49 `ok` / 5 `fallo`, de los que **4 se resuelven al repetirlos** y **1 es heredado** (`camara_pixeles`): el estado final es **53 `ok` / 1 `fallo`** — ver §7 |

Números de la auditoría en píxeles, por caso (muestras pautadas con el color que la línea
dice / cobertura de la ventana / ancho medido):

| caso | antes | ahora |
|---|---|---|
| `recta` | 16/16 (94 %), ancho 0,50 m | **16/16 (94 %)**, ancho 0,40 m |
| `aproximacion` | 11/11 (100 %) | **11/11 (100 %)** |
| `frenada` | 10/10 (59 %) | **8/8 (47 %)**, mínimo exigido 45 % |
| `salida` | 3/3 (50 %) | **7/7 (64 %)** |
| cromaticidad / pico / distancia entre estados | 0,72 / 201 / 133 | **0,27 / 134 / 68** |
| goma de la trazada (7 comprobaciones) | ok | **ok** |

Aviso honesto sobre `frenada`: su cobertura baja de 59 % a **47 %**, y el mínimo es 45 %.
Es el precio de una pintura más discreta en una pose en la que la mayor parte de las
estaciones están a más de 120 m, donde el listón proyecta menos de un píxel. El criterio no
se ha tocado; el número está en el registro (`auditoria-despues-2.log`) y en el informe de
la batería. Lo mismo explica por qué el caso `salida` se resuelve ahora en otra estación
(índice 2910 en vez de 2875, con 7 muestras sólidas en vez de 3): con la pintura nueva hay
más poses que cumplen el patrón con la línea medible.

Además, `.tools/recovery/linea-visual/contraste_por_estacion.py` mide el contraste real
estación a estación (la diferencia máxima por canal del cuadradito de 3×3, que es la misma
medida que usa la sonda para decidir si la línea se ve):

| caso | cobertura antes | cobertura ahora |
|---|---|---|
| `recta` | 94 % | 94 % |
| `aproximacion` | 100 % | 100 % |
| `frenada` | 59 % | 47 % |
| `salida` | 50 % | 73 % |

### `./verify.sh`

Resultado completo en §7 y en `.tools/recovery/integral/` (`checks.tsv` y
`verificacion-integral.json`).

---

## 6. APK

| artefacto | valor |
|---|---|
| ruta | `build/android/F1OneShot-BarcelonaMoto.apk` |
| tamaño | 247 634 688 bytes (236,2 MiB) |
| SHA-256 | `bdf266edad4ec41696cb0a271ec5ca31df6655a26498f92b10cb3ef29763359f` |
| compilado | 2026-10-16 02:03:52 (exportación del preset `Android`, `--export-debug`) |
| firma | certificado de Godot, SHA-256 `16add3e871c8f5960e1876fb20ff0cce444915a880d8c9b509f1095e5dddc4ff` |
| huella del APK **instalado** | idéntica a la del compilado (`compilado=bdf266ed…`, `instalado=bdf266ed…`, `.tools/recovery/integral/logs/huella_instalada.log`) |
| paquete | 176 archivos de `res://` en el APK; los 15 declarados por el preset y sus dependencias, con el GLB del circuito en la huella esperada (`empaquetado`, `.tools/recovery/check_packaged.py`) |

**Los materiales modificados viajan en el APK.** El shader de la pintura está **dentro** de
`scripts/driving_line.gd` (una sola pieza con el script, sin recurso aparte que se pueda
quedar fuera del paquete) y `empaquetado` comprueba que ese archivo y sus dependencias están
en el APK. Pero la prueba de que lo que corre en el teléfono es la pintura nueva no es el
paquete, es la **medida en el aparato** (§8): la pintura que dibuja el binario instalado sale
`(36, 70, 36)` con cromatividad **0,13**, y el material anterior pintaba **0,25** con el rojo
y el azul casi a cero; el APK lleva la nueva.

Nota de honestidad sobre las dos compilaciones: la batería completa (§7) corrió sobre el APK
`d8396c9c…` (01:41:52). Después se corrigió **un comentario** de `driving_line.gd` —citaba los
números de la ronda de calibración en vez de los de la paleta entregada— y cualquier cambio en
un script cambia el `.pck` y con él el APK: se recompiló (el de arriba), se instaló y se
repitieron **todas** las comprobaciones que dependen del binario (compilar, firma, empaquetado,
huella, instalación, huella instalada, arranque, lienzo, cámara en el dispositivo, línea en el
dispositivo y cámara de morro: **0 fallos**, `.tools/recovery/linea-visual/revalidar.sh` y
`revalidar.log`). El cambio entre las dos compilaciones es de comentario, no de material.

---

## 7. `./verify.sh`

Corrida completa sobre el APK `d8396c9c…`, con el AVD `PRO` (Pixel 9a, `emulator-5556`,
lienzo horizontal 2424×1080). Registro entero en `.tools/recovery/linea-visual/verify-despues.log`
y en `.tools/recovery/integral/` (`checks.tsv`, `verificacion-integral.json`).

```
resultado: FALLO
fallos obligatorios: ['lienzo', 'mando_dispositivo', 'lienzo_final', 'camara_pixeles', 'linea_dispositivo']
omitidas: ninguna
== Hay comprobaciones obligatorias que fallan.
```

**49 `ok` y 5 `fallo`** de 54 comprobaciones. La batería es **la misma** que antes de esta
fase (`sonda_linea`, `capturar_linea`, `capturar_linea_antes`, `audit_linea` y
`linea_dispositivo` ya existían; esta fase no añade ni quita comprobaciones: 54 antes, 54
ahora). La corrida de referencia inmediatamente anterior a esta fase
(`.tools/recovery/fase6-subviraje/verificacion-integral-despues-20261016-0037.json`, 00:37)
dejaba **51 `ok` y 3 `fallo`: `toque`, `camara_pixeles` y `linea_dispositivo`**. Con eso, el
antes/después es honesto: dos de aquellos tres fallos siguen ahí (uno es intermitente y otro es
heredado), la fase no ha roto ninguna comprobación nueva y el tercero (`linea_dispositivo`) ya
no falla. Qué es cada fallo de esta corrida, y qué se hizo con él:

| comprobación | fallo de la batería | qué era | estado ahora |
|---|---|---|---|
| `lienzo` | «falta `--size`» | el `dumpsys` del display no respondió **en ese momento** (corte de adb): `PANTALLA` salió vacía y la comprobación no pudo medir | **ok** al repetirla con el lienzo medido (2424×1080) — `.tools/recovery/integral/logs/lienzo.log` y `revalidar.log` |
| `lienzo_final` | igual | el mismo corte, en la captura del final de la conducción | **ok** al repetirla — `revalidar.log` |
| `mando_dispositivo` | «el joystick táctil real gira el coche» | la **inyección de toques** del arnés falló dos veces (el primer intento de la batería falla igual, y esa comprobación ya reintenta una vez); el juego no tenía nada que ver | **ok** al repetirla: el coche gira a los dos lados (‑3,59 g a la derecha, +1,37 g a la izquierda, guiñada ±0,38-0,78 rad/s) — `.tools/recovery/linea-visual/mando-reintento2.log` |
| `linea_dispositivo` | «la calzada del aparato sale azulada (19,0)» | **defecto de la VENTANA de la herramienta**, no de la pintura: la ventana de 0,40..0,85 de alto incluía la **carrocería azul del coche** (medido: 19/255 de dominante de azul en la carrocería y 2-5/255 en la calzada por delante). Ya fallaba **antes de esta fase y con la pintura anterior** (corrida de referencia de las 00:37, §7): fallaba siempre, midiera lo que midiera la línea | **ok** con la ventana corregida (la calzada por delante del coche, 0,40..0,58) y el verde exigido en cada captura — §8 |
| `camara_pixeles` | «de 0 a 45 km/h el coche no crece (184 → 167 px)» | **heredado, ajeno a esta tarea**: la captura de «0 km/h» es el coche **parado** en la salida, donde la cámara está más cerca, así que la silueta arranca más grande y el criterio de crecimiento monótono no se puede cumplir. Está documentado con los mismos números antes de esta fase en `.tools/recovery/fase-traseras/INFORME-FASE-TRASERAS.md` (§330: 37 `ok` y 1 `fallo`, `camara_pixeles`) y en `.tools/recovery/fase6-subviraje/INFORME-FASE-SUBVIRAJE.md` (§204) | sigue **fallo**, sin tocar: es un criterio ajeno y no se relaja ni se maquilla (§9.1) |

Y la comprobación que en corridas anteriores era intermitente, `toque` (acelerador, freno, mando
e insumisiones simultáneas, medidos en pantalla): **`ok` en esta corrida** (141 s, `TOUCH PASS=
True`), con el acelerador, el freno y el mando respondiendo por toques reales en el dispositivo.

Después de la batería se corrigió el defecto de `linea_dispositivo` (§8) y el comentario del
script, y se recompiló e instaló el APK (§6). Las comprobaciones que dependen del binario se
repitieron enteras sobre el APK nuevo: **0 fallos**.

---

## 8. Dispositivo Android

Todo lo de abajo sale del **APK instalado** (§6), no del editor.

### 8.1 La línea en el teléfono

`linea_dispositivo` mide las capturas que hace `fase-camara/capturar_dispositivo.py`
conduciendo **con toques reales** sobre los pedales, con la velocidad leída de la barra del
HUD (`capturas.json`), sobre la banda de calzada por delante del coche
(x 0,40..0,60 · y 0,40..0,58 del lienzo 2424×1080):

| medida | valor |
|---|---|
| pintura de la línea (verde de la textura de estado) | presente en **14 de 14** capturas con calzada a la vista, entre **1.180 y 1.701 píxeles** por captura, desde el reposo a **265 km/h** |
| color de esa pintura | mediana **(36, 70, 36)**; cromaticidad mediana **0,13** (el material anterior del GLB pintaba **0,25**, con rojo y azul prácticamente a cero) |
| calzada por delante del coche | dominante de azul mediana **4,0/255** en el peor caso (tope 8,0) |
| carrocería del coche (control, no se exige nada de ella) | **8-19/255** de azul: es lo que medía de verdad la ventana ancha que usé primero, y por eso la comprobación fallaba por culpa del coche y no de la pintura |

Registro: `.tools/recovery/integral/logs/linea_dispositivo.log` y
`.tools/recovery/linea-visual/linea-dispositivo-corregida.log`. Capturas para mirar:
`.tools/recovery/linea-visual/galeria-dispositivo.html` (en el panel derecho) y, en crudo,
`.tools/recovery/integral/shots/camara/` — `disp-009.png` es el verde a 232 km/h,
`disp-001.png` el mismo verde con el coche parado en la salida y `disp-012.png` la frenada.
En la **cámara de morro** (`morro_dispositivo`, `.tools/recovery/integral/shots/morro/`:
`dispositivo-morro.png`) la pintura se ve como una banda estrecha y apagada en el centro de la
calzada, sin brillo ni borde luminoso: es el cambio de vista, con el coche ocupando 0,467 del
ancho del encuadre en el morro contra 0,062-0,157 en persecución (la librea del coche, que es lo
que mide esa comprobación), y el cronómetro sigue avanzando alrededor del cambio.

### 8.2 El resto del aparato

| comprobación | resultado |
|---|---|
| `pantalla` | horizontal, pantalla completa, barras del sistema ocultas (`DISPLAY PASS= True`) |
| `lienzo` / `lienzo_final` | lienzo 2424×1080, **0 columnas negras**, mando en (186, 895)±8 y pedales en sus regiones, antes y después de conducir |
| `arranque` / `registro_limpio` | el juego arranca y anuncia la pista (HUD dibujado a los 30 s); registro sin errores |
| `toque` | `TOUCH PASS= True`: acelerador, freno, mando y entradas simultáneas por toques reales |
| `mando_dispositivo` | el joystick gira el coche a los dos lados (§7) |
| `cronometro` | avanza en el dispositivo |
| `camara_dispositivo` / `morro_dispositivo` | capturas a varias velocidades y cambio de vista con `input tap` real, con la carrera siguiendo |
| `huella_instalada` | el APK instalado coincide byte a byte con el compilado |
| `camara_pixeles` | **fallo heredado** (§7, §9.1): el coche no «crece» desde la captura del coche parado |

---

## 9. Problemas pendientes y limitaciones

1. **`camara_pixeles` (heredado, ajeno a esta tarea).** La comprobación mide en el teléfono si
   la silueta del coche crece con la velocidad y falla porque la primera captura es el coche
   **parado** en la salida: con el coche parado la cámara está más cerca y la silueta sale más
   grande (184 px) que al empezar a andar (167 px a 45 km/h), así que el crecimiento monótono no
   se puede cumplir. Está documentado con los mismos números antes de esta fase
   (`.tools/recovery/fase-traseras/INFORME-FASE-TRASERAS.md` §330 y
   `.tools/recovery/fase6-subviraje/INFORME-FASE-SUBVIRAJE.md` §204). No la he tocado: es un
   criterio ajeno y no lo relajo para que la batería salga verde; lo que propongo es cambiar el
   protocolo de captura (medir desde la primera captura **en marcha**), no el umbral.
2. **La cromaticidad del rojo y el amarillo entre sí.** Con la paleta apagada, la
   distancia ponderada entre amarillo y rojo baja a 68 (el mínimo exigido es 45). Se
   distinguen (la auditoría clasifica bien el 100 % de las muestras pautadas y la sonda del
   aparato comprueba aparte el verde), pero es el par más justo: si en el futuro se apaga
   más la pintura, conviene separar el rojo hacia abajo (más oscuro y menos verde) antes
   que tocar el umbral de la auditoría.
3. **La cobertura del caso `frenada`** queda en 47 % (mínimo 45 %): margen pequeño por
   diseño, porque la pintura discreta está pensada para que a más de 120 m se integre en el
   asfalto. No se ha tocado el criterio.
4. **La medida de «orla» (halo)** es la más floja de todas: el ruido de fotograma a
   fotograma (antialiasing temporal y microderiva de cámara) mueve bordes de la escena y
   contamina cualquier cuenta de píxeles cambiados fuera del listón. Se ha sustituido por
   la **mediana** del color del anillo, que es insensible al ruido pero no distingue un
   halo de un píxel del propio canto fundido: en `recta` el anillo a 12 px todavía mueve 9
   niveles porque a esa distancia cae en la fusión del borde. No hay ninguna comprobación
   que *demuestre* la ausencia de halo; lo que hay es el argumento de construcción
   (el material es **opaco**: sin mezcla alpha, sin orden de dibujo y sin halo posible) y
   las capturas para mirarlo.
5. **Juicio estético final.** Todo lo de arriba son medidas. Si la pintura todavía parece
   demasiado presente (o demasiado apagada) en las capturas, el ajuste es una sola
   constante: `color_*` en `driving_line.gd`, y hay herramienta para elegir el valor por el
   color que sale en pantalla (`.tools/recovery/linea-visual/calibrar.gd`), no a ojo.
