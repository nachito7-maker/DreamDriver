# ¿De dónde salía la vista aérea? — diagnóstico visual

Proyecto: **F1Godot** (Godot 4.7.2, Android). Fecha: **14-oct-2026, 01:46–02:00**.
Encargo: decidir si la imagen con perspectiva aérea, horizonte marrón y aspecto de maqueta
corresponde al juego en ejecución, al viewport 3D del editor de Godot o a otra ventana.

**No se ha modificado ningún archivo del juego, no se ha reconstruido el circuito, no se ha
tocado la cámara ni las físicas y no se ha exportado ningún APK nuevo.**

---

## 1. Qué se ha capturado

| # | Captura | Instrumento | Huella SHA-256 |
|---|---|---|---|
| 1 | App en marcha (2400×1080): `apk-en-ejecucion.png` | `adb exec-out screencap` sobre `emulator-5556`, APK instalado `605abf6a…` | `48440106864792d4…` |
| 2 | Referencia previa: `revert/shot-apk-recuperado-final.png` | ya existía (23:20) | `0cc6a15afa1c90fa…` |
| 3 | Editor con `scenes/race.tscn` abierto (1920×965): `ventanas/godot-editor.png` | `screencapture -l 15934` (ventana «race.tscn - F1 One Shot - Barcelona Moto - Godot Engine») | `c8bed3157b4028fe…` |
| 4 | Sólo el viewport 3D del editor: `viewport-godot-editor.png` | recorte (330,100)-(1700,900) de la anterior | `fbc8d7906e471888…` |
| 5 | Inventario de ventanas del escritorio: `ventanas.txt` | `winlist` (CoreGraphics, sólo lectura) | — |
| 6 | Candidatas aéreas del mismo circuito: `candidatas/`, `candidatas-unity-nuevas/` | copiadas del proyecto hermano `~/AndroidStudioProjects/F1` | ver `SHA256SUMS` |
| 7 | Caja del vehículo verificada a ojo: `crops/coche-marcado-apk-en-ejecucion.png` | `marcar_coche.py` sobre la captura 1 | — |
| 8 | Informe visual: `informe.html` | autocontenido (imágenes incrustadas) | — |

El editor se abrió **sólo** para el punto 5 del encargo (`--editor res://scenes/race.tscn`,
pid 51998) y se cerró al terminar; la instancia del gestor de proyectos que abrió
accidentalmente `open -a` (pid 51959) también se cerró. Ninguna de las dos escribió nada del
proyecto salvo el estado propio del editor (`.godot/editor/*.cfg`).

El APK instalado sigue siendo, byte a byte, el de la reversión:
`605abf6a160454085636b2146fa8c0d33380b871b1da457b8203a91560dc563c` (verificado con `sha256sum`
sobre el `base.apk` extraído del paquete instalado). Los guiones del juego mantienen las
huellas de la instantánea previa: `race.gd` `a245da302453…`, `race.tscn` `81b46924e52d…`,
`car_controller.gd` `1aee679ce517…`, `touch_controls.gd` `f94109d49b8d…`.

## 2. Medidas (mismo código para todas: `medir_vistas.py`)

| captura | cielo % | oscuro % | verde % | marrón % | calzada % | horizonte (% de altura) |
|---|---|---|---|---|---|---|
| APK en marcha | 28,2 | 13,3 | 7,7 | 0,8 | 30,2 | 2,4 |
| APK recuperado (referencia) | 16,2 | 6,5 | 7,6 | 2,7 | 35,6 | 2,4 |
| Ventana del editor | 1,8 | 82,2 | 0,1 | 0,0 | 9,0* | 12,2 (borde de barra) |
| Viewport del editor | 2,9 | 74,2 | 0,2 | 0,0 | 13,6* | 2,2 (borde de barra) |
| Unity · overview del GLB (17:37) | 0,0 | 1,7 | 0,1 | 9,6 | 6,7 | 53,0 |
| Unity · recta principal | 0,0 | 0,3 | 0,4 | 2,4 | 12,6 | 50,7 |
| Unity · curva rápida derecha | 0,0 | 0,2 | 0,0 | 10,2 | 25,5 | 76,9 |
| Unity · límites de pista | 0,0 | 0,1 | 0,2 | 7,5 | 7,0 | 1,7 |
| Unity · remastered overview (01:49) | 0,0 | 34,0 | 0,2 | 0,6 | 13,4 | 6,8 |
| Hoja de 6 vistas Unity | 0,4 | 37,6 | 2,3 | 0,0 | 3,2 | 22,7 |
| Blender · KN5 visto desde arriba | 0,0 | 0,1 | 0,4 | 0,5 | 61,9 | 44,8 |

\* En la ventana del editor esa columna mide grises de la propia interfaz, no asfalto: sólo es
interpretable en las capturas que representan la escena.

«cielo» = azul claro y luminoso; «oscuro» = luma < 45; «marrón» = R>G>B con contraste cálido;
«horizonte» = fila del mayor salto de brillo. Una vista a ras de suelo deja esa fila pegada
al borde superior (**2,4 %**); una cenital la lleva al centro (**50–53 %**).

## 3. Comparación pedida, punto por punto

| rasgo | aplicación en marcha | viewport del editor | candidatas aéreas |
|---|---|---|---|
| perspectiva | rasante (cámara de persecución) | vista de editor vacía | cenital u oblicua aérea |
| horizonte | fila al 2,4 % de la altura, con 28 % de cielo | ninguno (sin cielo) | al 44–53 % en las cenitales, 6,8 % en la aérea remastered |
| tamaño del coche | el vehículo con el piloto ocupa ≈13 % de la altura, centrado (`crops/coche-marcado-apk-en-ejecucion.png`) | sin vehículo | sin vehículo |
| disposición del circuito | la calzada llena el encuadre (30,2 % de los píxeles) | nada que disponer | la pista es una cinta dentro del terreno (3,2–25,5 %) |

## 4. Hallazgos

1. **La aplicación en marcha dibuja la vista de persecución**, no una vista aérea: 28 % de
   cielo azul arriba, asfalto y césped en el 97 % inferior, coche centrado. Su fotograma es
   coherente con la referencia previa (`shot-apk-recuperado-final.png`), que a su vez es
   idéntica byte a byte a `integral/shots/pantalla.png` y `final-apk.png`. La diferencia
   entre la captura de las 01:47 y la de las 23:20 es que el coche ha avanzado por la pista.

2. **El viewport 3D del editor no puede mostrar el circuito.** `scenes/race.tscn` tiene 7
   líneas: un `Node3D` llamado `Race` con `race.gd` y nada más; la pista, el coche, la cámara
   y el cielo se crean en `_ready()`/`_build_world()` al ejecutar. Medido: la ventana del
   editor es 82,2 % oscura con 1,8 % de cielo, 0,1 % de verde y **0,0 % de marrón**, y el
   recorte del viewport muestra sólo la rejilla de ejes del editor. La hipótesis «viewport del
   editor de Godot» queda descartada por esta evidencia, no por opinión.

3. **Sí existen vistas aéreas con aspecto de maqueta del MISMO circuito**, pero no las produce
   el juego ni el editor de este proyecto, sino el proyecto hermano
   `~/AndroidStudioProjects/F1` (`Tools/AC2026TrackPipeline` con Unity 6000.3.24f1):
   - `work/evidence/unity/f1godot/godot-overview.png` (17:37): diorama cenital del GLB.
   - `work/evidence/unity/remastered-visual-only/remastered-overview.png` (**01:49 de hoy**):
     vista aérea con terreno marrón y tejido urbano.
   - Hojas de contacto de 6 vistas (00:02 y 01:11) y `visual-review.html` (22:23), servidas
     por HTTP local para revisión en navegador (`127.0.0.1:8766` desde las 16:42, `8772`,
     `8089`, `8090`).
   - La procedencia es la misma revisión de este proyecto: `source-file-hashes.json` de esa
     evidencia registra `race.gd` `a245da302453…`, `race.tscn` `81b46924e52d…` y
     `BarcelonaMoto-Tutorial.glb` `d9ceb75798…`, idénticos a los de F1Godot hoy.

4. **Ninguna otra ventana del escritorio dibuja el circuito.** Inventario en `ventanas.txt`
   (`winlist`, nivel 0): ChatGPT, Freebuff, dos ventanas de Godot (editor y gestor), Tailscale,
   Android Studio (otro proyecto), Unity Hub, Safari (el sitio de Freebuff), Finder, Blender
   —abierto con `jugcampo-candidate.blend1`, una esfera/candidato de otro trabajo, no el
   circuito—, Chrome («Meshy»), TextEdit y Terminal. No hay ninguna ventana de Unity ni de un
   visor mostrando la pista.

## 5. Conclusión

- **Ni el juego en marcha ni el viewport del editor de Godot coinciden con la imagen
  descrita.** El juego dibuja la persecución a ras de suelo (horizonte medido al 2,4 % de
  altura, coche centrado) y el viewport del editor está vacío por construcción de la escena.
- **Lo que sí coincide con «perspectiva aérea + horizonte marrón + aspecto de maqueta» son las
  capturas Unity del mismo circuito** que en esas horas se estaban generando y sirviendo por
  HTTP para revisión desde el proyecto hermano F1 (17:37, 21:54, 00:02, 01:11 y 01:49). Son
  aéreas, muestran el circuito entero como una maqueta y su terreno es marrón. Ninguna de
  ellas lleva vehículo: el detalle «el coche parcialmente fuera del encuadre» no tiene
  candidata que lo explique entre lo capturado.
- Si la imagen del usuario salió de un navegador con una de esas páginas de revisión abiertas,
  la atribución a «la cámara del juego» es un malentendido entre dos proyectos distintos que
  trabajan el mismo circuito de Barcelona.

## 6. Limitaciones

- **La imagen original no está disponible como archivo** en este hilo, en el proyecto ni en los
  datos de la aplicación (`~/Library/Application Support/Freebuff`, `~/Library/Caches/…`): la
  comparación se ha hecho contra los rasgos que describes, no píxel a píxel. Para cerrarla del
  todo basta con dejar el archivo en el proyecto: `revert/comparar_vistas.py` ya calcula la
  diferencia media por píxel y la fila del horizonte entre dos imágenes.
- Las medidas de «marrón», «cielo» y «calzada» son umbrales fijos; describen, no identifican.
- El tamaño del coche sólo se da como cifra donde el detector se ha verificado a ojo; en el
  resto de capturas ese detector se confunde con la cartelería azul (`marcar_coche.py`).
- No se ha ejecutado el juego desde el editor (F5) ni se ha tocado el emulador más allá de
  `screencap`: la app quedó como estaba, en primer plano.
