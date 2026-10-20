# FASE 4 — Robustez de pantalla: dos resoluciones, una sola exigencia

Cierre: 14 de octubre de 2026. Continúa la
[`INFORME-FASE3-SUSPENSION.md`](../fase3-suspension/INFORME-FASE3-SUSPENSION.md).

**Resumen.** El juego ya se adaptaba a cualquier lienzo; la batería no. Las medidas de
pantalla estaban escritas contra 2400 × 1080: regiones absolutas en `screen_check.py`, un
`require image.size == (2400,1080)`, un literal `cur=2400x1080` en `check_display.py` y las
coordenadas del inyector de toques cableadas en `AndroidTouch.java`. En una pantalla de
1080 × 2424 eso hacía fallar `pantalla` y `lienzo` **sin que el juego tuviera ningún
defecto**, y el inyector clavaba el dedo 24 px fuera del centro de cada pedal —dentro del
pedal todavía, pero medido con la tolerancia de otra pantalla—: los pedales están anclados
al borde derecho, así que los mueve el ancho (§3.1).

Ahora las cuatro piezas derivan la geometría del tamaño real del aparato:

| Archivo | Qué hacía | Qué hace |
| --- | --- | --- |
| [`.tools/recovery/screen_geometry.py`](../screen_geometry.py) | No existía | **Nuevo.** Reproduce la aritmética de layout del juego (`race_hud.gd`, `touch_controls.gd`): anclajes a bordes/centro y escala por altura. Devuelve las regiones de medida, los puntos que pisa el inyector y el recorte de pantalla. `--selftest` comprueba que en 2400 × 1080 reproduce las regiones calibradas a mano. |
| [`.tools/recovery/screen_check.py`](../screen_check.py) | Regiones absolutas de 2400 × 1080; exigía ese tamaño exacto; umbrales en píxeles fijos | Regiones, tolerancias y umbrales derivados del tamaño detectado (`--size`, o `wm size` del aparato). Comprueba además HUD fuera del recorte (notch), mando en la mitad izquierda y los dos pedales en la derecha con el freno a la izquierda del acelerador. |
| [`.tools/recovery/check_display.py`](../check_display.py) | `if "cur=2400x1080" not in display: falla` | Mide: horizontal, `cur` = pantalla física, `app` = pantalla entera, la ventana del juego con `parent`/`display`/`frame` completos y las barras ocultas en **todos** los estados. |
| [`.tools/recovery/AndroidTouch.java`](../AndroidTouch.java) | `steerX = 186f`, `throttleX = 2288f`, `brakeX = 2111f` | Recibe las 10 coordenadas por argumentos desde `screen_geometry.py`; sin argumentos no inyecta nada. |
| [`verify.sh`](../../../verify.sh) | Descripciones y llamadas con 2400 × 1080 | Mide el lienzo una vez (`screen_geometry.py device`), lo imprime y lo pasa a `ready`, `layout`, `touch`, `clock` y `pantalla`. |

**No se ha tocado el juego.** Ni la escena, ni el HUD, ni los controles, ni la física, ni
la suspensión, ni las ruedas, ni el circuito, ni `project.godot`: el APK entregado es el
mismo. Lo que se ha arreglado son las herramientas de medida.

## 1. Auditoría: dónde estaba atada la resolución

### El juego ya era agnóstico

En `scripts/touch_controls.gd` y `scripts/race_hud.gd` todo se calcula desde el lienzo
real y se ancla a un borde:

```
escala        = clamp(alto / 900, 0,68 · 1,32)          # sólo depende de la ALTURA
telemetría    = posición (24, 20) · escala              # anclada arriba-izquierda
cronómetro    = centro_x ± 165 · escala                 # anclado al CENTRO
mando         = (155 · escala, alto − 154 · escala)     # anclado abajo-izquierda
pedales       = borde derecho − 46 · escala − 95 · escala, y desde abajo
área sensible = panel ± (22, 16) · escala
```

En las dos pantallas que hay que soportar la altura es 1080, así que **escala = 1,2 en
ambas**: los elementos miden exactamente lo mismo y lo único que cambia es la posición
horizontal de lo que está anclado al centro o a la derecha. Por eso expresar una región
como fracción del ancho habría sido incorrecto (los pedales se mueven 24 px al pasar de
2400 a 2424; la telemetría y el mando no se mueven nada), y por eso el módulo nuevo
reproduce la aritmética en vez de escalar cajas.

### Qué dependía de coordenadas absolutas

| Prueba medida | Dependencia | Cómo queda |
| --- | --- | --- |
| Regiones de HUD y mandos (`screen_check.py`) | Rectángulos fijos de 2400 × 1080 | Derivadas del tamaño detectado |
| `layout` (lienzo, mando, pedales, bandas negras) | `image.size == (2400,1080)`; mando en (186, 895) ±8 | Tamaño del aparato; mando y pedales en su anclaje derivado |
| Tolerancias del mando (14 px), raya mínima (20 px), umbrales de cambio (200/40 px) | Constantes en píxeles | Escaladas con el mando (el HUD escala con la altura) |
| `toque` (inyección) | `186f`, `2288f`, `2111f`, `830f`, `1042f` cableados | Argumentos desde la geometría |
| `toque` (detección de fases) | `cx >= 250`, `176 ≤ cx ≤ 205`, `cx − reposo ≥ 40` | Derivadas del centro y del radio del mando |
| `cronometro` | Región fija del panel central | Centrada: `centro ± 165 · escala` |
| `pantalla` | `cur=2400x1080` | `cur` = pantalla física en horizontal, ventana del juego completa |

## 2. Defectos reales encontrados al medir

Los tres salieron de medir, no de suponer, y ninguno era de resolución.

**a) El detector de pedales medía el circuito en vez del pedal.** `pedal_pressure`
contaba «píxeles rojizos» en el **área táctil** del pedal (que es el panel más 22×16 px de
relleno por lado). Alrededor del pedal se ve la pista, y con el coche pasando junto a una
valla roja midió **0,396 de freno con el freno sin tocar**: la detección de fases creyó que
la fase «freno + dirección» empezaba a los 35,7 s (cuando se soltaba el multitáctil) en vez
de a los 43,3 s, y las medidas de esa fase salieron sin sentido (mando `cx=191` en lugar de
`85`). Medido sobre el **panel dibujado** y exigiendo color saturado
(`r−g > 80` en el freno, `g−r > 80` en el acelerador):

| Momento | Antes (caja táctil, rojizo) | Ahora (panel, saturado) |
| --- | --- | --- |
| reposo | 0,039 | 0,029 |
| freno pisado | 0,575 | 0,685 |
| mundo tras una valla roja (falso positivo) | 0,396 | 0,046 |
| paisaje claro (falso positivo del acelerador) | 0,748 | 0,049 |

**b) `check_display.py` no miraba el marco de la ventana.** El control negativo (un volcado
con la ventana acotada a `frame=[0,40][2400,1040]`) **pasaba**: la expresión regular no
capturaba `frame=`, sólo `parent` y `display`, que no cambian. Ahora se exigen los tres
iguales al display y el error nombra cuál falla.

**c) Dos falsos negativos por el estado del coche.** `toque` inyecta los toques sobre una
conducción real cronometrada, así que a los 18 s y a los 43 s el coche puede estar ya
parado (o contra una valla). Exigir «frenar cambia la velocidad» sobre un coche detenido no
mide el control: mide dónde llegó el coche. Medido en vídeo durante el diagnóstico con un
contador de fotogramas en los que cambian los dígitos de velocidad —una métrica que la
versión final ya no publica: la herramienta **puntúa los píxeles** que cambian en los dígitos
y esa puntuación es la que sale en las corridas de §3.5—:

| Ventana | Antes de la corrección | Tras la corrección (diagnóstico) |
| --- | --- | --- |
| acelerador | 1147 | 1131 |
| freno (coche en marcha) | — | 1067 |
| freno (coche ya parado) | 6 | 6, con aviso explícito |
| multitáctil | 1147 | 1123 |
| freno + dirección | 6 | 6, con aviso y **86 fotogramas de freno y mando pisados a la vez** |

La comprobación sigue exigiéndose tal cual **cuando el coche venía en marcha** (medido en
el último segundo y medio antes de la fase: un coche que planea sin tocar nada no mantiene
la velocidad), y la respuesta del control se mide siempre por lo que se ve: el pedal
pintado pisado, el mando desviado al lado contrario y los fotogramas de simultaneidad. La
simultaneidad es una comprobación **nueva** que antes no existía.

## 3. Cierre: dos aparatos, dos paneles, la misma exigencia

Cada perfil es una corrida **completa** de `./verify.sh` (sin `SKIP_LONG`, sin reutilizar
nada de la anterior) sobre un aparato distinto. Las dos terminan igual:

| | Perfil 1 | Perfil 2 |
| --- | --- | --- |
| AVD / aparato | `Medium_Phone_3` (emulador, GPU host) | `PRO` (Pixel 9a, emulador, GPU host) |
| Panel físico | 1080 × 2400 · 420 dpi | 1080 × 2424 · 420 dpi |
| Lienzo horizontal | **2400 × 1080** | **2424 × 1080** |
| Lo que midió el arnés | `[pantalla] lienzo medido en el dispositivo: 2400x1080` | `...: 2424x1080` |
| `./verify.sh` | **OK — 33 comprobaciones, 0 fallos obligatorios, 0 omitidas** | **OK — 33, 0, 0** |
| Corrida | 14 oct 2026, 18:27 | 14 oct 2026, 19:41 |
| Duración de la prueba de toque | 149 s | 155 s |
| Arranque hasta el HUD | 37 s | 29 s |
| Evidencia | [`perfil1-2400x1080/`](perfil1-2400x1080/) | [`perfil2-2424x1080/`](perfil2-2424x1080/) |

Las dos listas de comprobaciones son la misma, con los mismos identificadores y las mismas
33 entradas: [`checks.tsv` del perfil 1](perfil1-2400x1080/checks.tsv) y
[`checks.tsv` del perfil 2](perfil2-2424x1080/checks.tsv). Ninguna se omitió y ninguna se
disimuló (el informe JSON de cada corrida dice `fallos_obligatorios: []`, `omitidas: []`,
`resultado: OK`).

### 3.1 Qué se mueve y qué no al cambiar de panel

Los dos lienzos miden 1080 de alto, así que la escala del juego es **1,200 en los dos** y los
elementos miden exactamente lo mismo; lo único que cambia de sitio es lo que está anclado al
borde derecho. Medido en las dos corridas (`pantalla.log` y `lienzo.log` de cada perfil):

| Medida | Perfil 1 (2400) | Perfil 2 (2424) | Diferencia |
| --- | --- | --- | --- |
| escala derivada de la altura | 1,200 | 1,200 | 0 |
| mando (anclaje derivado) | (186,0 · 895,2) | (186,0 · 895,2) | 0 |
| pedal del acelerador, centro x | 2287 | 2311 | **+24 px** |
| pedal del freno, centro x | 2110 | 2134 | **+24 px** |
| columnas negras | 0 | 0 | 0 |

Y esto es lo que recibe el inyector, que ya no lleva ninguna coordenada escrita a mano:

```
perfil 1   inyector coordenadas=[186.0, 895.2, 304.1, 85.6, 2287.8, 830.0, 1042.4, 2111.4, 830.0, 1042.4]
perfil 2   inyector coordenadas=[186.0, 895.2, 304.1, 85.6, 2311.8, 830.0, 1042.4, 2135.4, 830.0, 1042.4]
```

El mando no se mueve ni un píxel (está anclado abajo-izquierda y se mide desde su propio
anclaje) y los pedales se mueven 24 px porque se anclan al borde derecho. Si la medida se
hubiera escrito como fracción del ancho, el mando habría salido mal; por eso el módulo
reproduce la aritmética del juego en vez de reescalar cajas.

En el perfil 2 el pedal pintado mide 134 px de ancho y el dedo cae en su centro: la
tolerancia de la fase «pedal pisado» se calcula también desde el panel derivado, no desde
una constante.

### 3.2 Controles negativos: la medida no es vacía

Una comprobación que pasa en las dos pantallas no vale nada si pasaría también con la
medida equivocada. Cada artefacto archivado se ha vuelto a medir con **su** tamaño y con el
del otro perfil; sólo pasa con el suyo:

| Artefacto medido | `--size 2400x1080` | `--size 2424x1080` |
| --- | --- | --- |
| captura del perfil 1 (`lienzo`) | **0 · pasa** | 1 · falla |
| captura del perfil 2 (`lienzo`) | 1 · falla | **0 · pasa** |
| volcado del perfil 1 (`pantalla`) | — | 1 · falla |
| volcado del perfil 2 (`pantalla`) | — | **0 · pasa** |
| `screen_geometry.py --selftest` | **0 · pasa** (reproduce las regiones calibradas a mano de 2400 × 1080) | — |

El fallo no es genérico: el `lienzo` del perfil 1 medido como 2424 dice «la captura mide
2400x1080 y el lienzo del dispositivo 2424x1080 (el juego no llena la pantalla)». El control
más útil es el tercero y el cuarto, porque cubren el error que casi se comete en esta fase:
se forzó a mano el tamaño del panel del perfil 2 a 2400 × 1080 (el resto de la corrida
intacto) y `pantalla` **falla** con «el tamaño lógico actual (2400, 1080) no es el del
aparato (1080, 2424): el sistema está recortando o escalando la superficie»
([registro del control](perfil2-2424x1080/medidas/override-forzado.log), salida 1). Es
decir: un tamaño forzado sobre el panel real no puede colarse como si fuera otra pantalla,
que es exactamente lo que habría convertido esta fase en dos corridas idénticas contadas
dos veces.

### 3.3 El APK de las dos corridas

El juego no se ha tocado —el archivo más reciente de `scripts/`, `scenes/` y `assets/` es de
las 15:45, anterior a las dos exportaciones— y cada corrida comprueba que el APK que mide es
el que quedó instalado:

| | Perfil 1 (exportado 18:23) | Perfil 2 (exportado 19:33) |
| --- | --- | --- |
| Tamaño | 247 675 489 B | 247 675 489 B |
| sha256 compilado = instalado | `6ebbf7548df5f6ee…` = `6ebbf7548df5f6ee…` | `5a733273d0a3de8d…` = `5a733273d0a3de8d…` |

Las dos exportaciones **no son idénticas byte a byte**, y conviene decirlo con la medida
delante: los dos APK tienen 427 entradas con el mismo nombre, el mismo tamaño y el mismo CRC
—**0 entradas con contenido distinto**—, y lo único que difiere es la marca de tiempo del
ZIP de cada entrada (hora de exportación). Se comprobó reexportando otra vez desde el mismo
árbol y comparando entrada a entrada. Godot no produce un archivo reproducible; lo que sí
se garantiza, y se comprueba en cada corrida, es que lo instalado en el aparato es lo que se
acaba de exportar.

### 3.4 Arrancar un segundo emulador: lo que costó

No es parte del entregable, pero explica por qué la fase tardó en cerrar y evita repetirlo.

1. **El AVD del perfil 2 traía una resolución forzada** (`wm size 2400x1080` de un intento
   anterior) sobre un panel de 1080 × 2424. Sin `wm size reset`, el perfil 2 habría medido
   2400 × 1080 y la fase habría publicado dos corridas del mismo lienzo como si fueran dos
   pantallas. Se detectó al leer `Physical size:` y `Override size:` del aparato, se
   restableció, y desde entonces `pantalla` vigila la correspondencia entre el tamaño lógico
   y el panel físico (§3.2).
2. **El emulador no llegaba a arrancar con la memoria de invitada automática.** El AVD
   declara 2048 MB; el emulador los subía a 4096 y moría en la inicialización de gráficos
   —el informe del sistema de las 18:46 es un `SIGSEGV`/`EXC_BAD_ACCESS` de
   `qemu-system-aarch64`, y el registro del lanzador se corta justo después de «Vulkan
   emulation initialized»—, con el anfitrión en apuros (16 GB, un servicio WebKit de 4,4 GB,
   3,9 GB de compresor y 4 GB ya en swap). Acotando la invitada (`-memory 2048`) y quitando
   la ventana (`-no-window`) el mismo AVD arrancó en **12,7 s** y aguantó la corrida entera
   del perfil 2. No se aisló cuál de los dos factores —memoria del anfitrión o ventana— es la
   causa del `SIGSEGV`; lo que sí se repite es que con la invitada acotada arranca y con la
   automática no.
3. **El emulador tiene que ser un proceso persistente**, no un comando que se lanza y se
   espera: lanzado desde un comando síncrono, al terminar éste se enviaba la señal de
   parada al lanzador («Wait for emulator (pid …) 20 seconds to shutdown gracefully before
   kill») y el aparato desaparecía a mitad de la batería. Se lanzó como proceso aparte.

Receta de la corrida del perfil 2, para repetirla tal cual (el perfil 1 es igual, con el AVD
`Medium_Phone_3`, cuya panel es de 1080 × 2400):

```bash
AVD=PRO  # Pixel 9a: 1080 x 2424, 420 dpi, arm64-v8a, API 37
emulator -avd $AVD -port 5556 -no-boot-anim -gpu host -memory 2048 -no-window \
         -no-metrics -crash-report-mode disabled -no-snapshot-load -no-snapshot-save &
adb -s emulator-5556 wait-for-device
adb -s emulator-5556 shell wm size reset      # que no quede ningún tamaño forzado
SERIAL=emulator-5556 ./verify.sh
```

### 3.5 Lo que midió la prueba de toque en cada pantalla

La prueba de toque inyecta sobre una conducción real y mide la respuesta **en el vídeo de la
propia pantalla**; las dos corridas la pasaron con el coche en marcha en todas las fases, así
que no se activó ningún aviso. Cifras de
[`touch.json` del perfil 1](perfil1-2400x1080/touch.json) y
[`touch.json` del perfil 2](perfil2-2424x1080/touch.json):

| Medida | Perfil 1 (2400 × 1080) | Perfil 2 (2424 × 1080) |
| --- | --- | --- |
| fotogramas analizados (vídeo a 35,8 / 35,5 fps) | 2686 | 2659 |
| velocidad: cambio con el gas | 3158 | 3264 |
| marcha: cambio con el gas | 961 | 784 |
| velocidad: cambio con el freno | 2971 | 3000 |
| ¿el coche venía en marcha al frenar? | sí (100 fotogramas de planeo) | sí |
| velocidad: cambio con el multitáctil | 3217 | 3183 |
| mando: reposo → desvío máximo → vuelta al centro | 185 → 303 → 198 | 185 → 303 → 199 |
| gas en pantalla: reposo → pisado → liberación | 0,0344 → 0,9098 → 0,0073 | 0,0339 → 0,7951 → 0,0002 |
| freno en pantalla: reposo → pisado → liberación | 0,0493 → 0,9243 → 0,0418 | 0,0494 → 0,8585 → 0,0481 |
| freno + dirección: presión de freno / de gas | 0,8424 / 0,0400 | 0,8415 / 0,0316 |
| freno + dirección: mando al lado contrario | cx = 85 | cx = 85 |
| freno + dirección: fotogramas con los dos pisados a la vez | 94 | 90 |
| freno + dirección: cambio de velocidad | 913 | 896 |
| liberación total: presión máxima que queda | 0,0435 | 0,0449 |

Las dos corridas dan el mismo cuadro dentro del ruido del muestreo (el vídeo va a ~35 fps y
la detección de fases se hace por lo que está pintado en pantalla, no por el reloj de adb), y
en las dos el pedal que se pisa es el que corresponde, el mando vuelve al centro y el freno y
la dirección llegan a estar pisados **a la vez** durante más de 90 fotogramas: eso último es la
comprobación nueva que la fase anterior no tenía.

## 4. Limitaciones de esta fase (honestas)

1. **Los dos paneles se diferencian en 24 px de ancho**, con la misma altura (1080) y la
   misma densidad (420 dpi). Eso ejercita todo lo que depende del ancho —anclaje de los
   pedales, tolerancias del área táctil, detección de fases por posición del mando— pero deja
   **sin medir en el aparato** la rama de la escala vertical: la herramienta reproduce
   `clamp(alto/900, 0,68 · 1,32)` y en los dos perfiles la escala vale 1,200, igual que la
   calibración original. Un lienzo más alto (tableta 1600 × 2560 en horizontal) o uno más
   bajo (móvil pequeño) movería la escala y nadie lo ha corrido en un aparato todavía; el
   `--selftest` sólo comprueba el caso 2400 × 1080.
2. **Sigue sin haber un teléfono físico**: las dos corridas son emuladores con GPU del
   anfitrión. La fase no cambia las cifras de fluidez ni de latencia táctil de la entrega
   anterior.
3. La prueba de toque inyecta sobre una conducción real cronometrada, así que depende del
   estado del coche; las dos corridas cayeron con el coche en marcha en todas las fases
   (`freno_venia_en_marcha: true`, `freno_direccion_venia_en_marcha: true`) y por eso ningún
   aviso de «ya venía parado» aparece en los registros archivados. Sigue siendo el punto
   frágil conocido: un coche detenido obliga a leer un aviso en vez de una cifra (§2.c).
