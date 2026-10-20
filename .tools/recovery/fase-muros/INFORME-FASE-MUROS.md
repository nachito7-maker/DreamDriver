# Fase: los muros invisibles de la calzada

- Fecha: 2026-10-15
- Encargo: los dos vídeos del cliente (`9879.mp4` y `9880.mp4`) en los que el coche
  se clava sobre el asfalto a más de 200 km/h sin que se vea nada delante.
- Copia de recuperación anterior a tocar nada:
  `.tools/recovery/fase-muros/backup-20261015-1230` (`shasum -a 256 -c SHA256SUMS`).
- Resultado: la causa era una malla de **física** del circuito original de Assetto
  Corsa —relieve del suelo, no suelo ni muro— que sobresalía hasta 9 cm del asfalto
  y **no está dibujada**. Se hunde 1,50 m y el coche pasa por encima a 310 km/h.

## 1. El síntoma, medido en los vídeos

Los vídeos se miden fotograma a fotograma con `.tools/recovery/fase-muros/video_audit.py`
(velocidad de la barra del HUD, posición del mando y de los dos pedales, con la
geometría del lienzo que reproduce `screen_geometry.py`). Las trazas quedan en
`videos/` y el informe en `auditoria-videos.log`; cada suceso deja su fotograma en
`fotogramas/`.

| vídeo | fotogramas | máximo | suceso | antes | después | g |
|---|---|---|---|---|---|---|
| 9880.mp4 | 1409 (23,56 s) | 244,4 km/h | caída t=17,057 s | 241,4 km/h | 0,0 km/h | 408,8 |
| 9879.mp4 | 2400 (40,21 s) | 211,6 km/h | caída t=14,943 s | 107,3 km/h | 55,1 km/h | 88,2 |
| 9879.mp4 | | | caída t=33,956 s | 208,6 km/h | 134,1 km/h | 42,0 |

Después de la caída, los dos coches quedan parados con el acelerador pisado: el de
9880 durante 6,47 s a ≤10,4 km/h (acelerador 0,23–0,65) y el de 9879 durante 5,81 s
a 0 km/h (acelerador 0,50 y después 0,03). En los dos vídeos el mando va centrado
(mando en reposo en 1230 de 1409 lecturas y en 2112 de 2400): van en recta. Un coche
de 241 km/h que pasa a 0 en un fotograma, sobre asfalto y sin nada delante, es un
muro invisible.

## 2. Qué había en el circuito

La malla de física que trae el circuito tiene grupos que en Assetto Corsa **no son
suelo ni muro, sino relieve del suelo**: `MARBLES` (goma de las ruedas), `BUMP`
(badenes), `GRILLE` (rejillas), `TRAV` (cruces) y `CNCPTS` (escalones de hormigón).
Son cinco cuerpos y 16 668 caras (`sonda_relieve`).

En AC eso no molesta porque su coche son cuatro rayos de rueda: se rueda por encima.
Aquí el coche es una **caja rígida contra una malla trimesh**, así que un escalón es
un muro, y como las mallas de física no se dibujan, el muro es invisible.

Medido sobre la geometría tal como la entrega AC (`relief_probe.gd -- --original`):

- **865 de las 16 668 caras** sobresalen más de 5 cm del suelo que tienen justo
  debajo; la peor, **+0,09 m** (estación 590 del trazado).
- Y esas caras no tienen nada dibujado alrededor: `visual_cover_probe.gd` construye
  colisiones temporales con las **mallas visibles** y raya alrededor de cada cara de
  física que sobresale; **244 caras sobresalen sin nada dibujado a menos de 25 cm**
  (144 de `BUMP` en la banda de 0–0,5 m, 43 de `MARBLES`, 12 de `GRILLE`).
  Registro: `cobertura-visual.log`.

Un escalón de 9 cm explica el frenazo del vídeo: el fondo del coche lo golpea, la
cara vertical del escalón le da una normal horizontal y `move_and_slide` lo detiene
en el sitio —241,4 → 0 en un fotograma, 408,8 g— y después el coche no puede subirlo.

## 3. La corrección

`scripts/race.gd`:

```
_hundir_relieve_de_calzada()   # RELIEF_SINK_M = 1.5 m
```

Desplaza hacia abajo la **forma de colisión** de los cinco cuerpos de esos grupos.
No se toca ninguna otra colisión —ni muros, ni vallas, ni guardarraíles, ni
bordillos, ni las superficies de la pista— y no se cambia ningún material ni ninguna
malla visible.

Por qué 1,50 m: la cara de relieve más alta sobresale +0,09 m de su suelo (medido
arriba), así que 1,50 m deja **todas** las caras al menos 1,41 m por debajo del
asfalto en cualquier punto del trazado (el peor caso medido tras la corrección).

Por qué no se mide cara a cara en tiempo de ejecución: la versión que aplanaba cada
vértice contra el suelo con un rayo costaba 50 000 consultas al espacio contra mallas
de 300 000 caras —más de siete minutos de arranque— y se descartó. El hundimiento es
una constante justificada por la medida, y el arranque no paga nada: la escena entera
—cargar el circuito, montarlo, hundir el relieve— arranca en 5,63 s y el hundimiento
son cinco desplazamientos de forma, sin una sola consulta al espacio
(`relief_flatten_check.gd`).

## 4. Verificación

**(1) `sonda_relieve` (obligatoria en `./verify.sh`)** — dos medidas independientes:

- Cara a cara: las **16 668** caras de relieve medidas contra el suelo que tienen
  justo debajo. Por encima del tope de 5 cm hay **0**; la más alta de todas está
  **1,41 m por debajo**.
- Contra el original: se vuelve a montar el circuito desde el `GLB` **sin pasar por
  la escena de carrera** y se compara cuerpo a cuerpo por su nombre. **16 cuerpos en
  su sitio (0,00 m)** y **5 de relieve hundidos exactamente 1,50 m**.

**(2) `sonda_recto` (obligatoria)** — la maniobra de los vídeos llevada al extremo:
acelerador a fondo desde la salida y ni un toque de dirección durante 30 s. Máximo
**313,5 km/h**; pasa la estación 408 a 295,0 km/h, la 462 a 302,0 y la 518 a 310,3,
todas sobre `TRM-BRC`, con las cuatro ruedas en el suelo y agarre 1,00. Sólo se
detiene al final, **55,1 m fuera de la trazada y sobre `SAND`**, por no girar: eso es
conducción, no un fallo de colisiones. Registro: `recto.log`.

**(3) La causa, probada en el mismo binario (A/B)** — con `--relieve-como-antes` la
sonda devuelve el relieve a la altura que tiene en la malla original (+1,50 m, ni más
ni menos) y exige lo contrario: que el coche **sí** se clave sobre el asfalto. Y se
clava: la misma maniobra, el mismo pedal a fondo y la misma dirección (ninguna)
terminan en **estación 549, a 4,84 m de la trazada —sobre `TRM-BRC`—, tras alcanzar
313,5 km/h**, y en los 3 s siguientes con el acelerador a fondo el coche sólo avanza
**8,75 m**. El motor de física publica contra qué: `OTHER__physics (MARBLES)`, que es
el cuerpo de la goma de rueda, el mismo grupo que se mide más arriba. Sin el
hundimiento, esa misma pasada llega a 313,5 km/h y no se detiene sobre el asfalto.
Registros: `recto-antes.log` y `recto.log`.

**(4) `sonda_replay` (obligatoria)** — la velocidad medida en cada vídeo se reproduce
dentro del juego pisando el pedal de verdad y sin tocar la dirección:

| vídeo | máximo al reproducir | final | en la zona del choque del vídeo |
|---|---|---|---|
| 9880 | 237,4 km/h | estación 504, sin clavarse | t=17,0 s: 231,6 km/h sobre `TRM-BRC`, 4 ruedas |
| 9879 | 204,8 km/h | estación 503, sin clavarse | t=14,9 s: 103,9 km/h; t=34,0 s: 203,7 km/h, sobre `TRM-BRC` |

El criterio es el que importa: **sobre la calzada el coche no puede quedarse
clavado**. Salirse por no girar y detenerse fuera es conducción y se informa con el
cuerpo que lo paró.

**(5) La batería completa** `./verify.sh`, con el código definitivo: **46
comprobaciones, resultado `OK`, 0 fallos obligatorios y 0 omitidas** (informe en
`.tools/recovery/integral/verificacion-integral.json`). Incluye el APK firmado, la
instalación sin incremental y la **huella SHA-256 del APK instalado**, que coincide
con la del compilado: `3b696574520d105afec63a073128c71d24c8acafc8caef7f7a43adc43bdf121c`.
En el dispositivo, conduciendo con toques reales, el coche llega a **270,2 km/h**
—por encima de los 241,4 km/h del vídeo— sin clavarse; la vuelta completa del
anfitrión (528,3 s) se da con **0 golpes contra muros**, 2,37 m de error máximo
respecto a la trazada y **como mínimo dos ruedas en el suelo en todo momento** (14
fotogramas de vuelo, ninguno con menos de dos contactos).

**(6) Las dos zonas en el APK INSTALADO, con vídeo** — la maniobra de los vídeos en el
aparato, con toques reales y **sin tocar la dirección**
(`.tools/recovery/fase-muros/recto_device_check.py`): el coche sale de la línea y sube
a **303,0 km/h** (0, 0, 31,8, 119,2, 204,6, 257,3, 293,0, 295,0, 303,0, 303,0 km/h cada
2 s), es decir **cruza las tres velocidades en las que se clavaron los vídeos —107,3,
208,6 y 241,4 km/h— sin detenerse**, y la imagen no se congela en ningún intervalo
con el coche rodando (7 intervalos, cambio mínimo 0,249). Sólo se para al final, al
salirse por no girar (t≈20 s), que es conducción. Deja 15 capturas (cada 2 s), la
traza de velocidad leída de la barra del HUD, el vídeo de la pantalla
(`recto-device.mp4`, 18 MB) y `recto.json` en
`.tools/recovery/fase-muros/shots/recto-device/`. Y la salida de pista, medida con el
mismo arnés que ya usaba la fase
(`.tools/recovery/offtrack_device_check.py`): **PASS**, el coche sigue rodando fuera
del asfalto con la imagen cambiando en los 10 intervalos de la rodadura (cambio mínimo
0,074), sin errores en el registro del dispositivo.

## 5. Lo que ha aparecido al quitar el muro

La sonda de la cámara del morro medía su caso «curva» **con el coche detenido por el
relieve**: sostenía 130 km/h en el viraje más cerrado del trazado (radio 30 m, ~3,8 g
de agarre lateral) y el coche acababa fuera, dentro de la barrera. Antes de esta fase
el caso pasaba porque el relieve invisible lo paraba antes de salirse: el listón
aprobado de esa fase estaba midiendo el defecto.

Se ha arreglado el **escenario**, no el criterio: la curva se conduce ahora por el
viraje **más cerrado que el coche puede tomar a 130 km/h** con un límite de agarre
lateral declarado (0,9 g), y el caso exige, de forma explícita, que el coche **siga
sobre la calzada y a ≤4 m de la trazada** al medir la composición. La banda de píxeles
(0,25–0,61 del alto) no se ha tocado: la franja medida es 0,32.

El escenario pasó por dos correcciones, las dos medidas. La primera versión conducía
a la velocidad que permite el viraje de radio 30 m —41 km/h, 0,4 g— y ahí apareció un
segundo problema del mismo caso: con la dirección tan girada, uno de los neumáticos
delanteros queda tapado por la carrocería (medido: 9 269 px, 0,36 % del lienzo, por
debajo del 0,5 % que el caso pide), así que la composición que exige el caso no puede
darse en un viraje así. La versión final **conduce** a 121,1 km/h por el viraje de
radio 148 m —0,27 g pedidos, 0,27 m de la trazada, sobre `TRM-BRC`— y toma las
**fotografías con el coche detenido en el mismo punto** del viraje: a velocidad,
cuánto neumático delantero enseña la cámara no es reproducible —el mismo neumático
sale con 51 377 px en una pasada y con 10 049 px en otra, mismo viraje y misma
velocidad, con la suspensión dentro de su recorrido (±0,7 mm), sin topar y con 0,03°
de dirección—, mientras que la composición no depende de eso (la cámara es rígida:
0,0000 m de deriva). Detenido en el mismo punto, el estado es el de la sonda «parado»
y se repite al 2 % (dos pasadas: 35 372 y 35 876 px en el neumático izquierdo). La
franja del coche queda en 0,32–0,34 en las seis situaciones.

Y una segunda cosa, también medida: **una sola regla para las seis**. La sonda pinta
el coche de magenta plano para recortar su silueta por color, y mientras las
fotografías de la curva se tomaban rodando esa captura traía además una banda magenta
en la parte alta del cuadro que el fotograma normal dibuja como cielo (medido: la fila
200, columna 1200 de `composicion-curva-coche-magenta.png` salía (255, 0, 255) y la
misma del fotograma normal, (151, 187, 205)), con el borde superior en la fila 142 y
franja 0,87, frente a 418 147 px y franja 0,316 por diferencia; en la curva decidía la
diferencia. Con la fotografía detenida la banda no aparece: las dos reglas dan la
**misma** franja y el mismo borde superior en las seis situaciones (difieren 0,0000;
0,316–0,336 con y0 entre 717 y 739). El medidor calcula las dos y ahora **exige que
coincidan** (se admite 0,05), así que una captura pintada que vuelva a traer geometría
que no es el coche se publica como fallo en vez de cambiarse la regla. El cambio está
en `.tools/recovery/fase-fp/morro_pixeles.py`.

## 6. Límites de esta fase

- De las 16 668 caras de relieve, **1 550 no tienen suelo que medir** (el rayo no
  encuentra superficie: quedan sobre un hueco o dentro de otra geometría) y quedan
  fuera de la medida cara a cara. El caso que importa —el coche pasando por encima a
  fondo— lo cubren la prueba de recta y la reproducción de los vídeos.
- El hundimiento es una constante. Su valor sale de la medida geométrica (+0,09 m de
  máximo y 1,4 m de margen) y lo comprueba `sonda_relieve` en cada pasada.
- La pasada del aparato mide la velocidad **de la barra del HUD** (no de una sonda
  interna, que allí no la hay) y juzga hasta la mayor de las tres velocidades de
  choque de los vídeos: cruzados los 241,4 km/h, lo que sigue es salirse de la pista
  y se informa, no se juzga. La superficie pisada y la estación del trazado las mide
  el anfitrión, que sí tiene la sonda dentro.
- Las dos comprobaciones del aparato no están dentro de `./verify.sh`: necesitan el
  emulador libre y la batería ya lo ocupa durante su propia fase de dispositivo. Se
  ejecutan a mano con los dos comandos de la sección 7 y su resultado es el de arriba.
- El arranque de 5,63 s está medido en el anfitrión y sin ventana; en el aparato el
  arranque se comprueba por otra vía (que el juego anuncie la pista y dibuje el HUD).
- El relieve no se ha retirado: sigue ahí, debajo de la calzada.

## 7. Cómo se reproduce

```bash
cd /Users/indenova/AndroidStudioProjects/F1Godot

# 1. La medida de los vídeos (una vez, con los vídeos del encargo)
python3 .tools/recovery/fase-muros/video_audit.py ~/Downloads/9880.mp4 ~/Downloads/9879.mp4 \
    --salida .tools/recovery/fase-muros/videos --fotogramas .tools/recovery/fase-muros/fotogramas
python3 .tools/recovery/fase-muros/video_audit.py ~/Downloads/9879.mp4   # informe 9879-audit.log

# 2. El relieve tal como lo entrega AC y tal como queda en el juego
"$GODOT" --headless --path . --script res://scripts/relief_probe.gd -- --original
"$GODOT" --headless --path . --script res://scripts/relief_probe.gd
"$GODOT" --headless --path . --script res://scripts/visual_cover_probe.gd

# 3. La maniobra de los vídeos, con y sin el hundimiento del relieve
"$GODOT" --path . --script res://scripts/straight_run_probe.gd
"$GODOT" --path . --script res://scripts/straight_run_probe.gd -- --relieve-como-antes

# 4. La velocidad de los vídeos, reproducida dentro del juego
"$GODOT" --path . --script res://scripts/video_replay_probe.gd -- 9880 9879

# 5. Todo, incluido el dispositivo
./verify.sh

# 6. Las dos zonas en el APARATO, con toques reales (necesita el emulador libre)
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/fase-muros/recto_device_check.py \
    emulator-5556 .tools/recovery/fase-muros/shots/recto-device
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/offtrack_device_check.py \
    emulator-5556 .tools/recovery/fase-muros/shots/offtrack-device
```

## 8. Ficheros de esta fase

| fichero | qué es |
|---|---|
| `auditoria-videos.log`, `9880-audit.log`, `9879-audit.log` | medida de los dos vídeos, medio segundo a medio segundo |
| `videos/*.json`, `videos/*.csv` | trazas medidas (velocidad, mando, pedales) |
| `fotogramas/*.jpg` | el fotograma de cada suceso |
| `relieve-original.log` | el relieve tal como lo entrega AC |
| `cobertura-visual.log` | qué caras que sobresalen están dibujadas y cuáles no |
| `recto.log` | la prueba de recta (relieve hundido) |
| `recto-antes.log` | la misma prueba con el relieve a su altura original: se clava |
| `curva_estado.gd` | reproduce aparte el caso «curva» de la sonda del morro y publica el estado del coche |
| `replay.log` | la reproducción de los dos vídeos |
| `.tools/recovery/AndroidRecto.java`, `recto_device_check.py` | la maniobra de los vídeos en el APARATO: acelerador a fondo, sin dirección, con capturas, vídeo y traza de velocidad del HUD |
| `shots/recto-device/`, `shots/offtrack-device/` | las capturas, el vídeo y los informes JSON de las dos pasadas en el dispositivo (instalado el APK de la entrega) |
| `backup-20261015-1230/` | copia de recuperación anterior a tocar nada |
