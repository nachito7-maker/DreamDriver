# F1 ONE SHOT GODOT — CIERRE Y VALIDACIÓN

> **Cierre posterior (15 de octubre de 2026, fase ruedas TRASERAS — el tambor plateado):**
> la captura mostraba las ruedas traseras «rotas» y no era la forma: **era que a la goma le
> faltaba superficie**. El activo entregado trae la goma de cada trasera partida en **cuatro
> gajos de 90° que no se cosen entre sí** (más cuatro restos de 16 vértices en las juntas: ocho
> piezas por rueda) —la huella del «relleno por simetría de revolución» con que el proyecto
> anterior reconstruyó **sólo las traseras** (`produce_fleet.py` §11b: «se conserva el sector de
> 90° mejor cubierto y se rota tres veces más»)— y por las juntas se veía el **barril metálico de
> la llanta**. Medido con 2880 rayos por rueda que entran de fuera hacia el eje: en las traseras
> **el 61,9 % de las direcciones daban en la llanta y el 3,6 % atravesaban la rueda**, frente al
> **100 % de goma** de las delanteras. Ninguna medida de la cadena lo veía —caja envolvente,
> silueta (0,00 mm de dispersión), diámetros, corona y **cobertura angular exacta (100,0000 % en
> las dos situaciones)**— porque todas miran la FORMA, y el defecto era que **faltaba
> superficie**.
>
> Esta fase añade esa medida al auditor (**VISIBILIDAD**: la primera superficie que ve un rayo
> lanzado de fuera hacia el eje tiene que ser goma en la banda de rodadura) y **sustituye sólo la
> goma de las dos traseras** por una **funda de revolución cerrada** generada con las medidas del
> propio activo (radio exterior 372,89 mm —el mismo que ya tenía—, agujero en el **barril medido**
> de su llanta 231,42 mm + 1 mm, anchura 457,48 / 457,68 mm, cantos planos y 256 gajos) y con la
> misma construcción, enrollado y convención de normales de la goma delantera. El activo se
> parchea **a nivel binario, sin pasar por Blender**: el BIN original queda como prefijo exacto
> del nuevo y los nodos, materiales, texturas, la carrocería y **las dos ruedas delanteras**
> quedan byte a byte idénticos (26 595 516 → 26 743 940 bytes; la goma vieja queda como datos
> muertos, declarado en las limitaciones).
>
> Resultado: la goma de cada trasera pasa de **8 piezas a 1** y su visibilidad de **22,1 % a
> 100 %** (llanta vista: 61,9 % → 0; se veía el fondo a través de la rueda: 3,6 % → 0); la
> auditoría de malla pasa de **2 problemas (salida 1) a 0 (salida 0)**; las cuatro ruedas siguen
> apoyadas (aire bajo la rueda −5,4 mm las traseras, 4 contactos, pose 0,066°, pivote 0,0000 m,
> órbita al girar 0,0000 m) y el radio cambia +0,03 mm. En la propia captura del juego (parado,
> alineada píxel a píxel) los 8 989 píxeles que cambian en el primer plano de la rueda trasera se
> **oscurecen en el 97 %** (luminancia 100,0 → 53,2; píxeles de metal claro 1394 → 59): la llanta
> desaparece bajo la goma, que es lo que se veía roto.
>
> La corrida de cierre de la batería con el activo reparado dio **OK — 38 comprobaciones,
> 38 `ok`, 0 fallos obligatorios, 0 omitidas** (con la prueba nueva `audit_ruedas_malla`
> dentro), APK recompilado, firmado, instalado y con el `base.apk` extraído del dispositivo
> idéntico al compilado:
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 220db4eecaa490d24155335df46b7e5b54e00035f4271fd7701fa298f326f603` · 247 605 857
> bytes (dos exportaciones de las mismas fuentes dan 427 entradas con el mismo tamaño y CRC,
> sólo cambian las marcas de tiempo del ZIP). El activo entregado queda en
> `assets/RedBull-Drive.glb` `e68bce2b…` · 26 743 940 bytes y el circuito sin tocar
> (`d9ceb757…`).
>
> La **primera** corrida de esa batería —37 `ok` y **1 fallo**— señaló `camara_pixeles`, y el
> que estaba mal era el instrumento, no las ruedas: en `disp-009` (192,7 km/h) la mancha
> elegida era una **banda de asfalto en sombra** de 1 067 px de ancho (toda la ventana de
> búsqueda) con **58 016 px** de semilla de azul oscuro, frente a los 12 885 del coche, que en
> la misma captura medía **219 px** de alto (entre los 191 de 152 km/h y los 244 de 229,5).
> Ahora se descartan los candidatos que **atraviesan la ventana**, es decir que tocan **dos o
> más** de sus bordes: la banda tocaba tres, el coche no toca ninguno en las 12 capturas del
> anfitrión ni en 15 de las 16 del teléfono (en la que toca uno sigue midiéndose bien, y de
> hecho ése es el caso que descarta la regla ingenua de «no tocar ningún borde»). La
> validación del clasificador contra la resta real de fotogramas **no se movió** —3,4 % de
> peor desvío, la misma cifra caso por caso—, de las 16 capturas del teléfono **sólo cambia la
> elección en `disp-009`** (187 → 219 px) y el factor del dispositivo pasa de 1,48 a **1,74**,
> con la serie de aceleración otra vez monótona (126 · 133 · 149 · 206 · 219 px) y la frenada
> intacta. El fallo y los dos lados del arreglo quedan archivados en
> `.tools/recovery/fase-traseras/evidencia-camara/`, y el caso está contado desde el otro lado
> en [`INFORME-FASE-CAMARA.md` §9.4](.tools/recovery/fase-camara/INFORME-FASE-CAMARA.md).
>
> El detalle completo —causa raíz, diferencias medidas con las delanteras, la prueba que faltaba
> y por qué las anteriores no la veían, y las limitaciones honestas (**la llanta conserva cuatro
> grietas del mismo artefacto, medidas en el 2,2 % de las direcciones por el eje, ~1,6 px en el
> primer plano del juego**, y no se han tocado a propósito)— está en
> [`INFORME-FASE-TRASERAS.md`](.tools/recovery/fase-traseras/INFORME-FASE-TRASERAS.md), con las
> galerías [`comparativa-camara-juego.html`](.tools/recovery/fase-traseras/comparativa-camara-juego.html),
> [`comparativa-ampliada.html`](.tools/recovery/fase-traseras/comparativa-ampliada.html),
> [`comparativa-traseras.html`](.tools/wheels/render/comparativa-traseras.html) y
> [`comparativa-rr.html`](.tools/wheels/render/comparativa-rr.html), y la copia de recuperación del
> estado de partida en `.tools/recovery/fase-traseras/backup-20261015/` (huella `a1d3f7ff…`).

> **Cierre posterior (15 de octubre de 2026, fase cámara — el coche se alejaba al correr):**
> la queja era real y tiene una causa medida: la cámara no medía su distancia en el sistema del
> coche, sino con un suavizado exponencial sobre una referencia **móvil**, y ese filtro deja un
> error de seguimiento permanente de `v/λ` metros —la separación crecía 8,9 m entre parado y
> 200 km/h sin que ninguna línea cambiase la distancia—. Ahora la distancia se calcula en el
> sistema del coche y **decrece** con la velocidad (11,4 m parado → 7,2 m a 198 km/h o más), y
> sólo se filtra el parámetro de velocidad (0,55 s al acercarse, 0,85 s al alejarse, y la
> anticolisión acorta distancia si un muro se interpone). Medido con dos instrumentos
> independientes (la proyección de la caja del modelo con la cámara real y la **resta de dos
> fotogramas del mismo instante, con y sin coche**, que no usa ninguna variable del juego), el
> coche pasa de ocupar el 20,4 % del alto parado y el 8,2 % a 200 km/h —factor 2,5× **más
> pequeño** al correr, que era la queja— a ocupar el 14,4 % parado y el 27,6 % a 200 km/h:
> **factor 1,92× más grande al correr**. La frenada devuelve la cámara de forma monótona (0
> cambios de sentido, salto máximo 0,017 m por fotograma) y sin histéresis: 11,38 m al final de
> la frenada contra 11,39 m parado.
>
> La comprobación no se queda en el anfitrión: `verify.sh` **conduce el juego en el aparato con
> toques reales** (los mismos `input swipe` sostenidos sobre los pedales que usa la prueba de
> controles), captura la pantalla mientras acelera y frena, lee la velocidad de la **barra del
> HUD en la propia imagen** y mide el coche en píxeles. Las 16 capturas de la corrida final van
> de 126 px parado a 225 px a 195,7 km/h (**factor 1,79**, criterio ≥ 1,45) y encogen al frenar;
> la barra del HUD llega a **261,3 km/h** en la recta principal, muy por encima del «200» que la
> sonda del anfitrión mantiene con su lazo de control.
>
> Por el camino la batería encontró **dos defectos del instrumento** y los arregló sin tocar el
> juego ni relajar ningún criterio: la medida de píxeles del teléfono elegía la mancha más grande
> y en `disp-006` el **césped** le ganaba al coche por 132 px (15 077 contra 14 945), así que
> ahora la mancha se elige por la **librea azul oscura del chasis**, con la validación intacta
> (3,4 % de peor desvío contra la resta real de fotogramas); y la comprobación de orientación
> exigía `ROTATION_90`/`270` cuando este AVD declara `mLandscapeRotation=ROTATION_0`, con la
> ventana ya perfectamente horizontal y a pantalla completa. Los cuatro volcados retorcidos con
> los que se probó el arreglo siguen fallando.
>
> `./verify.sh` en la corrida final (AVD `PRO`/Pixel 9a, lienzo horizontal 2424×1080): **OK — 38
> comprobaciones, 0 fallos obligatorios, 0 omitidas**, con el APK recompilado, firmado e
> instalado y el `base.apk` extraído del dispositivo **idéntico**
> ([`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 bb7d907c46a25a604f0b8b18ef7bee9a9b8b875794180f1280163eaa2b65dbc6` · 247 695 969 bytes),
> y el circuito y el coche sin tocar (`BarcelonaMoto-Tutorial.glb` `d9ceb757…` · 188 646 600
> bytes, `RedBull-Drive.glb` `a1d3f7ff…` · 26 595 516 bytes). Todo el detalle —la causa, las dos
> medidas caso por caso, la anticolisión probada con un muro sintético porque este circuito no
> la necesita (0 posiciones), y las limitaciones declaradas, incluida la dispersión del 11 %
> entre capturas del aparato a la misma velocidad— está en
> [`INFORME-FASE-CAMARA.md`](.tools/recovery/fase-camara/INFORME-FASE-CAMARA.md), con la galería
> antes/después en `.tools/recovery/fase-camara/comparativa.html`.

> **Cierre posterior (14 de octubre de 2026, fase 5 — forma de las ruedas del Red Bull):** la
> captura que mostraba las ruedas «deformadas, rotas o mal ensambladas» tenía detrás dos
> defectos de geometría medidos: **las delanteras eran óvalos** (diámetros 761,51 × 745,97 y
> 762,33 × 747,42 mm, 15,5 y 14,9 mm de diferencia) y **las traseras tenían cuatro muescas de
> 12,20 mm repetidas cada 90°** (residuo de periodicidad **0,000 %**), que son las cuatro
> costuras del «relleno por simetría de revolución» con que el proyecto anterior reconstruyó esa
> rueda. El defecto **ya venía en su LOD0** (`VehiclePrototypes/_backup_fill_20260921/redbull/model.fbx`:
> mismos radios —378,60 / 380,97 / 381,56 mm—, mismas anchuras y el mismo patrón de muescas) y
> su criterio de aceptación —cobertura ≥ 93 % del radio— daba **72/72 sectores** porque las
> muescas llegan a **0,968 R**: era ciego a la profundidad. La cobertura mide si *hay* banda,
> no si la banda es redonda. Ninguna comprobación de la cadena miraba la forma: la caja de
> `audit_delivery.py`, la sonda de ruedas y la de suspensión daban `passed=true` con las ruedas
> ovaladas y con muescas.
>
> Se corrige en el activo (no en ejecución) con un **torneado radial del neumático anclado en
> el talón** —el asiento sobre la llanta no se mueve: los vértices de la goma en la banda del
> barril cambian ≤ 0,25 mm—, se rehace el reparto goma/llanta para que caiga en el barril (estaba
> 25-42 mm por dentro) y se reasienta cada rueda para que su fondo siga en y = 0 del modelo. La
> silueta pasa de 7,94 / 7,93 / 12,20 / 12,20 mm a **0,01 / 0,08 / 0,00 / 0,00 mm**, los dos
> diámetros coinciden en las cuatro ruedas, la auditoría de malla pasa de **10 problemas a 0** y
> los cuatro fondos quedan **más coplanares que antes** (6,8 → 1,8 mm de dispersión). Las dos
> causas raíz, los dos intentos fallidos y por qué fallaron, la comparación medida de 42 capturas
> con el mismo encuadre y las limitaciones honestas están en
> [`INFORME-FASE-RUEDAS.md`](.tools/recovery/fase-ruedas/INFORME-FASE-RUEDAS.md), con la galería
> comparativa en `.tools/recovery/fase-ruedas/comparativa.html`, `./verify.sh` en **OK (34
> comprobaciones, 0 fallos obligatorios, 0 omitidas)** —una más que la fase anterior porque la
> regresión incorpora la auditoría de forma `audit_ruedas_malla`, que era la que faltaba— y el APK
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 f35a3413197e921c7e9d96291977728756090c9480ff116662a9f16228b8008e` ·
> 247 695 969 bytes · instalado y con el `base.apk` extraído del dispositivo idéntico.
>
> La copia de recuperación del estado de partida (las ruedas deformadas) está en
> `.tools/wheels/backup-antes-redondeo/`, con la huella `9c601ee1…` y las instrucciones para
> volver atrás.

> **Cierre posterior (14 de octubre de 2026, fase 4 — dos resoluciones):** el juego ya se
> adaptaba a cualquier lienzo; quien no se adaptaba era la batería de medidas. Estaban
> escritas contra 2400 × 1080: regiones absolutas en `screen_check.py`, un
> `require image.size == (2400, 1080)`, un literal `cur=2400x1080` en `check_display.py` y las
> coordenadas del inyector de toques escritas a mano en `AndroidTouch.java`. Ahora las cuatro
> piezas derivan la geometría del tamaño real del aparato, con un módulo nuevo
> ([`screen_geometry.py`](.tools/recovery/screen_geometry.py)) que reproduce la aritmética de
> layout del juego (anclajes a los bordes y escala por altura) y tiene `--selftest`.
>
> **No se ha tocado el juego**: el archivo más reciente de `scripts/`, `scenes/` y `assets/`
> es de las 15:45, anterior a las dos exportaciones de esta fase; lo que cambió son las
> herramientas de medida. Lo que se ha medido es la batería entera, dos veces, sobre dos
> paneles distintos, sin relajar ningún criterio:
>
> | | Perfil 1 | Perfil 2 |
> | --- | --- | --- |
> | Aparato | `Medium_Phone_3` (1080 × 2400 · 420 dpi) | `PRO`/Pixel 9a (1080 × 2424 · 420 dpi) |
> | Lienzo horizontal | 2400 × 1080 | 2424 × 1080 |
> | `./verify.sh` | **OK — 33 comprobaciones, 0 fallos, 0 omitidas** | **OK — 33, 0, 0** |
>
> El único elemento que cambia de sitio entre las dos pantallas es lo que está anclado al
> borde derecho: **los dos pedales se mueven 24 px** (centro del acelerador 2287 → 2311 y del
> freno 2110 → 2134); el mando no se mueve ni un píxel, porque se ancla abajo-izquierda. En el
> perfil 2 el inyector recibe esas coordenadas medidas, no constantes. Los controles negativos
> están en el informe: cada captura y cada volcado archivado se vuelve a medir con el tamaño
> del otro perfil y **falla**, y un tamaño forzado a mano sobre el panel del perfil 2 también
> falla, de modo que las dos corridas no pueden ser el mismo lienzo contado dos veces.
>
> El APK se ha reexportado desde las mismas fuentes en cada corrida y cada corrida comprueba
> que lo instalado coincide con lo compilado (`sha256` iguales). Con el mismo contenido: los
> dos APK de esta fase, y un tercero reexportado para comprobarlo, tienen 427 entradas con el
> mismo tamaño y el mismo CRC y **0 entradas con contenido distinto**; lo único que difiere
> es la marca de tiempo del ZIP. Godot no produce un archivo reproducible byte a byte, y el
> APK entregado es el de la segunda corrida:
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 5a733273d0a3de8da9efb1eb54ebaf9bbdacdd61212a4a2199555f10ffbad7c4` ·
> 247 675 489 bytes · firmado en depuración, arm64-v8a.
>
> Todo el detalle, las medidas y las limitaciones (las dos pantallas comparten altura y
> densidad, así que la rama de la escala vertical sigue sin medirse en un aparato) están en
> [`INFORME-FASE4-RESOLUCIONES.md`](.tools/recovery/fase4-resoluciones/INFORME-FASE4-RESOLUCIONES.md).

> **Cierre posterior (14 de octubre de 2026, fase 3 — suspensión):** el Red Bull ya no lleva
> las ruedas rígidas. Cada rueda tiene recorrido vertical propio (35 mm de compresión y
> 30 mm de extensión) resuelto con un rayo bajo cada rueda, y el chasis se apoya en el
> equilibrio de los cuatro muelles con la transferencia de carga real: al frenar se hunden
> las delanteras y se extienden las traseras, al acelerar al revés y en curva se comprimen
> las exteriores. Todo el detalle, las diez pruebas y los límites están en
> [`INFORME-FASE3-SUSPENSION.md`](.tools/recovery/fase3-suspension/INFORME-FASE3-SUSPENSION.md),
> con `./verify.sh` en **OK (33 comprobaciones, 0 fallos obligatorios, 0 omitidas)** y el APK
> actual
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 82837facaeeab04374c3c9c533a3870ee10fcd884ed3b83b6c651b65ccc29e60` ·
> 247 675 489 bytes, instalado y con el `base.apk` extraído del dispositivo idéntico.
>
> Dos cosas que la fase 3 encontró **al verificar en el dispositivo**, no en el anfitrión:
> el APK no llevaba el script nuevo —el `include_filter` del preset enumeraba a mano los
> scripts anteriores, así que `preload("res://scripts/wheel_suspension.gd")` fallaba en el
> teléfono y el juego arrancaba sin compilar la escena—, y el emulador con el que empezó la
> fase era un Pixel 10 de 1080 × 2424, que no es la geometría del lienzo calibrado
> (2400 × 1080). Ambas cosas están corregidas y ahora las vigila una comprobación
> obligatoria nueva, `empaquetado`, que audita el contenido del APK contra el preset y contra
> las dependencias que precargan los scripts. La corrida final se hace sobre un AVD de
> 1080 × 2400 (`Medium_Phone_3`, densidad 420, GPU host): el AVD `F1Recovery` de esta acta ya
> no está registrado y `F1` apunta hoy a un Pixel 10.

> **Cierre posterior (14 de octubre de 2026, fase 2 — ruedas):** la auditoría de las
> ruedas del Red Bull, la reconstrucción del modelo y la verificación completa están en
> [`INFORME-FASE2-RUEDAS.md`](.tools/recovery/fase2-ruedas/INFORME-FASE2-RUEDAS.md),
> con `./verify.sh` en **OK (31 comprobaciones, 0 fallos obligatorios, 0 omitidas)** y el
> APK de esa fase (hoy sustituido por el de la fase 3, arriba)
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 01b2ec6a4496401e89a16bc06741bf0c2d56b86bd9604bfa84c7ab84200b599f` ·
> 247 667 130 bytes. Las cuatro ruedas pasaron de estar entre 7,0 cm hundidas y 5,8 cm en
> el aire (12,8 cm de desnivel) a quedar a menos de 5 mm del asfalto parado, en recta a
> 206 km/h y en curva a 111 km/h.

> **Cierre posterior (14 de octubre de 2026):** la auditoría de colisiones, la corrección de
> la dirección y el arreglo de la medición del mando están en
> [`INFORME-FASE1-COLISIONES.md`](.tools/recovery/fase1-colisiones/INFORME-FASE1-COLISIONES.md),
> con la corrida completa de `./verify.sh` en **OK (29 comprobaciones, 0 fallos obligatorios,
> 0 omitidas)** y el APK de esa fase (hoy sustituido por el de la fase 3, arriba)
> [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
> `sha256 abc85b2b834a6cd8528eb8574a8bb5105f4790baf33e8cf282bea7c10bfb13e9` ·
> 247 667 130 bytes. El resto de este documento es el acta del cierre anterior (13 de
> octubre, APK `8097dc…`) y se conserva tal cual.

Fecha de cierre: 13 de octubre de 2026. Máquina: macOS (Apple M1). Motor: Godot 4.7.2 stable, render `gl_compatibility`.

APK definitivo: [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
`sha256 8097dc8c876a978f7138afb4c287d69e1916df757aeeea8a28339987317bd747` · 247 667 130 bytes · exportación final 2026-10-13 19:39:48 · firmado en depuración, arm64-v8a. El `base.apk` extraído tras la instalación final de las 19:48 coincide byte a byte (misma SHA-256).

**Cierre adicional de pantalla completa, aceleración y controles (13 de octubre, APK SHA `8097dc…`):** después de reinstalar y comparar el APK final, se volvió a ejecutar el HUD/layout, gas, freno, multitáctil, cronómetro y captura final, todo con PASS sobre el mismo APK. Resultados: [retest final](.tools/recovery/final-retest.json), [video y JSON de controles](.tools/recovery/integral/shots/toque-hash-final/touch.json), [log de toques](.tools/recovery/integral/logs/toque-hash-final.log), [captura final](.tools/recovery/integral/shots/final-hash-screen-after.png). Resolución real `2400×1080`, landscape inmersivo, cero columnas negras. El intento agregado tiene problemas de ADB/device-offline y medición cromática al soltar freno; quedó separado como fallo del harness, no se contabiliza como fallo funcional de la repetición independiente.

---

## 1. Qué se ha hecho en esta ejecución

El trabajo anterior (conversión, física, controles y APK) ya estaba hecho. Esta ejecución **audita ese estado, corrige lo que las pruebas demostraban defectuoso y revalida todo sobre un APK reconstruido desde el árbol actual**. Cambios reales:

| Archivo | Cambio |
| --- | --- |
| [`scripts/race.gd`](scripts/race.gd) | Iluminación: luz ambiental neutra (`AMBIENT_SOURCE_COLOR`, 0.42) en lugar de cielo azul a 0.65 y sol de 1.10 → 1.05. Motivo medido abajo (§5). |
| [`scripts/render_probe.gd`](scripts/render_probe.gd) | Nuevo. Renderiza la escena real y **mide** el color del asfalto. |
| [`scripts/fps_probe.gd`](scripts/fps_probe.gd) | Nuevo. Mide fps reales de la escena. |
| `assets/` | Cuarentena de 308 archivos (314 MB) de una conversión **obsoleta y no usada** a `.tools/stale-conversion/`. Ver §2. |

Evidencia automática: [`verificacion-final.json`](.tools/recovery/verificacion-final.json), capturas y registros en `.tools/recovery/` y `.tools/recovery/logs/`.

## 2. Conversión del circuito: procedimiento y procedencia real

Se siguió el procedimiento del artículo obligatorio (KN5 → OBJ → Blender → glTF), con estas herramientas, todas verificadas en ejecución:

- **KN5 → OBJ**: `jes/kn5-converter` en `.tools/tutorial-conversion/jes-kn5-converter/` (compilado con Mono `mcs`).
- **Lectura de metadatos KN5**: `assetto-corsa-gltf` (`acgltf.kn5`) para extraer superficies, materiales y banderas de visibilidad.
- **Montaje y export glTF**: Blender 5.2 LTS (`blender-track.log`, `blender-rebuild-mats.log`, `blender-export-textured.log`).
- **Import en Godot**: `assets/BarcelonaMoto-Tutorial.glb`, 119 nodos, 119 mallas, 120 materiales y **123 imágenes originales decodificadas** (no hay colores provisionales).

Fuente real: `fn_barcelona/models_barcelona_2023.ini` (9 KN5) + `barcelona_2023/data/surfaces.ini` + `barcelona_2023/ai/fast_lane.ai`.

**No hay dos copias superpuestas.** El APK exporta exactamente un circuito: la escena importada `BarcelonaMoto-Tutorial.glb` (57,48 MB). El proyecto tenía además una conversión anterior (`BarcelonaMoto.glb` + 300 texturas duplicadas) que ninguna escena ni el preset de exportación usaban; se movió a `.tools/stale-conversion/` para que el árbol tenga una única pista.

## 3. Variante obligatoria: Barcelona-Catalunya moto, sin chicane final

El paquete AC trae dos configuraciones y **la única diferencia entre ellas son dos KN5**:

```
models_barcelona_2023.ini       (moto)   → barcelona_remastered_moto.kn5 + barcelona_remastered_physics_moto.kn5
models_barcelona_gp_2023.ini    (GP)     → barcelona_remastered_chicane.kn5 + barcelona_remastered_physics_chicane.kn5
```

Pruebas de que se usó la de motos y no la de F1:

1. La lista de conversión son los 9 KN5 de `models_barcelona_2023.ini`, que **no incluye** ningún `*_chicane.kn5` (no se convirtió nunca).
2. El GLB del juego contiene 4 nodos de la capa moto y **0 nodos de chicane**.
3. La trazada es la del propio layout moto: `assets/BarcelonaMoto.fast_lane.ai` = `barcelona_2023/ai/fast_lane.ai` (`sha256 ff1e3e4d…`), distinta de la del layout GP (`0f32f0c7…`).
4. Geometría del tramo final (medida sobre los `.ai` reales): en los últimos 420 m la línea moto tiene radio mínimo **92,2 m y 3 cambios de sentido**; la línea GP tiene **51,8 m y 5 cambios** — la huella del chicane lento que la moto no tiene.
5. En el dispositivo, el registro del juego imprime: `[track] Barcelona 2023 Moto layout (no final chicane) | source fast_lane.ai | points=3057 | sampled spline length=4611.4 m`.

## 4. Estado del artefacto antes de tocar nada

El APK que estaba instalado antes de esta reparación no es el definitivo de este cierre. Se volvió a exportar el preset Android desde las fuentes actuales a las 19:39, se instaló sin incremental y se extrajo el archivo `base.apk`; su SHA-256 (revalidada tras otra instalación a las 19:48) coincide con el APK entregado (ver §7).

## 5. Iluminación y materiales (causa + corrección medida)

Las capturas anteriores mostraban asfalto azulado y canales recortados. Diagnóstico, en tres pasos:

1. **No era el emulador**: la escena renderizada en la GPU nativa del host mostraba el mismo tinte. Se descartó la traducción OpenGL ES→Metal.
2. **No eran las texturas**: el asfalto de AC es de albedo neutro (`asph_updt` (80,80,80), `road-concrete-ext` (100,96,90)) y en el GLB todos los materiales tienen `baseColorFactor` blanco. El tinte lo introducía la **luz ambiental de cielo a 0,65 de energía** (cielo `#4e85b5`): sobre albedo neutro producía `(146,180,202)` y recortaba el azul de las líneas blancas a 255.
3. **Corrección**: ambiente neutro (`(0.75,0.76,0.78)` × 0.42) y sol 1.05. Medición objetiva de la banda de asfalto:

Mismas bandas de asfalto en el mismo encuadre (desviación = separación entre canales respecto al mayor; 0 % es gris puro):

| banda | APK anterior, en el dispositivo | APK definitivo, en el dispositivo | APK definitivo, render del host |
| --- | --- | --- | --- |
| asfalto izquierda | (161,190,198) · **18,7 %** | (166,172,168) · **3,1 %** | (154,162,170) · 9,8 % |
| asfalto derecha | (144,176,197) · **27,0 %** | (149,158,165) · **9,8 %** | (159,168,175) · 8,6 % |

El resto de las saturaciones de azul desaparecieron (recorte 0 % de píxeles en las bandas medidas).

Se conservan las texturas originales, los 120 materiales, los 34 materiales con *normal map* y las transparencias del mod (los decales de goma `groove`/`groove3` y las líneas son `BLEND`, como en el origen, con umbral de recorte 0,35). La franja gris-azulada del centro es la goma de la trazada del propio mod (`groove.png` = (84,87,104) con alfa ~50), no un defecto de importación.

## 6. Física, joystick y pedales — sondas sobre el árbol final

Ejecutadas en headless con `Godot 4.7.2`, todas con código de salida 0:

- **Circuito** (`track_probe`): 3057 puntos, 4611,4 m, spawn y rumbo coherentes.
- **Runtime** (`runtime_probe`): 4 contactos de rueda, `floor=true`, **177,2 km/h** tras acelerar 95,3 m, **frenada a 0,008 km/h**, ruedas girando (`rotating=true`), altura de carrocería sincronizada.
- **Controles** (`controls_probe`): pedales separados y no solapados; **acelerador a la derecha, freno a la izquierda**; multitáctil (gas + dirección simultáneos) con `throttle=1.0` y dirección progresiva; más desplazamiento = más giro; el soltar no provoca un tirón; **entrada física y joystick visual vuelven al centro** (error < 0,001 y distancia al centro < 0,3 px); el freno solo frena; recorrido del pedal analógico; liberación correcta al levantar el dedo.
- **Cronometraje** (`lap_probe`): cruce inverso ignorado, el primer cruce arranca el cronómetro, un cruce sin sectores no cuenta vuelta, tiempo anterior y mejor vuelta ordenados, la mejor vuelta solo la mejora una vuelta válida.
- **Vuelta completa** (`driving_probe`, 507 s de simulación): resultado histórico del árbol anterior `FULL_LAP passed=true ...`. Esta vuelta larga se omitió en la última corrida (`SKIP_LONG=1`) y **no se atribuye a la compilación actual**; las sondas de pista, runtime, controles y cronometraje sí volvieron a pasar en la corrida que exportó el APK actual.

## 7. APK definitivo: instalación y verificación en el emulador

Dispositivo de revalidación: `F1Recovery` (`emulator-5556`, GPU host).

1. **Instalación verificada**: el APK recompilado a las 19:39:48 se reinstaló sin incremental y se extrajo `base.apk` a las 19:48:30; se volvió a instalar y comparar a las 19:49. Tamaño 247 667 130 bytes y ambas extracciones coinciden con SHA-256 `8097dc8c876a978f7138afb4c287d69e1916df757aeeea8a28339987317bd747`. Evidencia: [`base-instalada.apk`](.tools/recovery/integral/base-instalada.apk) y [`final-retest.json`](.tools/recovery/final-retest.json).
2. **Horizontal y pantalla completa**: `requestedOrientation=SCREEN_ORIENTATION_LANDSCAPE`, superficie/captura 2400×1080, `ROTATION_90`; status/navigation bars ocultas en 2/2 estados. Medición de layout: `columnas_negras=0`, controles en sus regiones. Evidencia [`pantalla.log`](.tools/recovery/integral/logs/pantalla.log), [`pantalla.png`](.tools/recovery/integral/shots/pantalla.png) y [`pantalla-final.png`](.tools/recovery/integral/shots/pantalla-final.png).
3. **Arranque**: 109 s hasta el HUD en la corrida integrada actual (compilación shader+carga completa); registro de Barcelona Moto, sin errores críticos del juego en logcat.
4. **Entrada táctil simultánea, medida en el video de la superficie Android y revalidada en el APK por SHA**: 306 fotogramas a 5.115 fps. Gas: cambio de velocidad 2099 px y marcha 472; freno: cambio de velocidad 1856; gas+dirección simultáneos: cambio de velocidad 3067, joystick `cx=185→289`. Presiones gas `0.0547→0.5703→0.0492` y freno `0.0389→0.5706→0.0895` (reposo→pisado→liberación). Joystick vuelve a `cx=190`. Evidencias: [`touch.json`](.tools/recovery/integral/shots/toque-hash-final/touch.json), [`touch.mp4`](.tools/recovery/integral/shots/toque-hash-final/touch.mp4), [`fases-velocidad-marcha.jpg`](.tools/recovery/integral/shots/toque-hash-final/fases-velocidad-marcha.jpg), [`toque-hash-final.log`](.tools/recovery/integral/logs/toque-hash-final.log).
5. **Cronómetro y persistencia visual, mismo hash instalado**: el reloj avanzó (`3589/67320` píxeles cambiados en el panel); la captura posterior conserva HUD y mandos a `2400×1080`, sin bandas negras. Evidencia: [`clock-hash-final.log`](.tools/recovery/integral/logs/clock-hash-final.log), [`final-hash-screen-after.png`](.tools/recovery/integral/shots/final-hash-screen-after.png).

El registro [`checks.tsv`](.tools/recovery/integral/checks.tsv) conserva los fallos instrumentales de verify.sh; su estado global es **FALLO**, no se disfraza como PASS. Tras la última reinstalación y verificación de SHA, se repitieron arranque, layout, toque multitáctil, cronómetro y captura final en ese mismo APK; todo pasó. El reporte distingue esa evidencia del fallo del harness en [`final-retest.json`](.tools/recovery/final-retest.json) y [`handoff-evidence.json`](.tools/recovery/handoff-evidence.json).

## 8. Rendimiento (sin confundirlo con un teléfono)

- **GPU nativa del host, 1920×1080**: **79,7 fps** (`fps_probe`, 600 fotogramas, 7,53 s). Referencia de que la escena no está limitada por CPU de juego.
- **Emulador**: no sirve como referencia. Con `-gpu host` el reloj del juego avanza **3,87 s por cada 21 s reales (≈18 %)**, es decir, el emulador no sostiene tiempo real; el proceso consume ~77–91 % de un núcleo. Además, `screencap`/`SurfaceFlinger --latency` no exponen el búfer del `SurfaceView` en este modo; las capturas se tomaron con la consola del propio emulador (`screenrecord screenshot`).

## 9. Limitaciones pendientes (honestas)

1. No se ha probado en un teléfono físico: las cifras de fluidez y de latencia táctil son del emulador y del host, no de un dispositivo.
2. El glTF empaqueta mapas *metallic/roughness* para 30 de 120 materiales; los otros 90 utilizan rugosidad escalar reconstruida de los materiales fuente. El canal y el valor se auditaron píxel a píxel para los 30 mapas disponibles y no hubo errores; 34 materiales conectan *normal maps*. Algunos detalles de micro-rugosidad no se conservan como texturas dedicadas para todos los materiales.
3. Las dos capas de chicane del mod (`*_chicane.kn5`) no se convierten por diseño: son la variante GP, no la moto pedida.
4. La carga inicial en el emulador tarda ~90–105 s (compilación de shaders + 178 MB de geometría). No se ha medido en un teléfono.
5. La corrida integrada de `verify.sh` conservó errores `device offline` en la detección inicial y una captura de freno integrada tuvo falso positivo cromático del emulador. Tras confirmar el SHA instalado `8097dc…`, se repitieron secuencialmente la prueba táctil completa, el cronómetro y layout final; todos pasaron. El estado agregado sigue en FALLO y el retest exitoso queda identificado por separado, no se atribuyen esos PASS a la corrida fallida.
6. La comprobación de retorno del joystick admite ±14 píxeles para compensar el muestreo escaso del emulador; en la última repetición su centro final fue `cx=192` frente al centro nominal `186`, tras desviarse a `cx=294` con gas simultáneo.

## 10. Cómo se reproduce todo

```bash
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --headless --path . -s scripts/track_probe.gd        # circuito
$G --headless --path . -s scripts/runtime_probe.gd      # aceleración/frenada/ruedas
$G --headless --path . -s scripts/controls_probe.gd     # joystick y pedales
$G --headless --path . -s scripts/lap_probe.gd          # cronometraje
$G --headless --path . -s scripts/driving_probe.gd      # vuelta completa
$G --path . -s scripts/render_probe.gd                  # color del asfalto
$G --path . -s scripts/fps_probe.gd                     # fps del host
$G --headless --path . --export-debug "Android" build/android/F1OneShot-BarcelonaMoto.apk
```

---

## 11. Fases posteriores al primer cierre

Después del cierre de octubre se han ido resolviendo, una por una y con informe propio,
las cosas que el juego hacía mal: muros invisibles y escapatorias
([fase 1](.tools/recovery/fase1-colisiones/INFORME-FASE1-COLISIONES.md)), ruedas y
suspensión ([ruedas](.tools/recovery/fase2-ruedas/INFORME-FASE2-RUEDAS.md),
[suspensión](.tools/recovery/fase3-suspension/INFORME-FASE3-SUSPENSION.md)), pantallas
y resoluciones ([fase 4](.tools/recovery/fase4-resoluciones/INFORME-FASE4-RESOLUCIONES.md))
y, ahora, la **cámara de persecución**
([informe completo](.tools/recovery/fase-camara/INFORME-FASE-CAMARA.md)).

### 11.1 La cámara se alejaba al correr: causa y corrección

La queja era que, al aumentar la velocidad, el coche se veía más pequeño. La causa no
era ninguna decisión de diseño: la cámara se colocaba con un **suavizado exponencial
sobre una referencia móvil** (`eye.lerp(car + offset, 1-exp(-6·delta))`). Un filtro así,
contra un objetivo que se traslada a `v`, no converge al objetivo: se queda con un error
de seguimiento **permanente de `v/λ` metros**, y como "atrás" es justo hacia fuera del
coche, la separación crecía con la velocidad sin que ninguna línea de código lo pidiera.
A 107 km/h eran 4,95 m de más; a 191 km/h, 8,8 m; a 200 km/h, 9,2 m, sobre los 9 m de
base. La predicción `9 + v/6` reproduce lo medido con menos de 0,3 m de error en todo el
rango (tabla en el informe). Además la cámara se resolvía en `_process` mientras el coche
se mueve en `_physics_process`: un fotograma de retraso, 0,92 m a 200 km/h y temblor
cuando los dos relojes se desfasaban.

La corrección mueve el cálculo a la **capa correcta**: el desplazamiento se construye en
el sistema del coche (donde es constante y no acumula error) y lo que se filtra es el
**parámetro de velocidad**, no la posición.

| Parámetro (`scripts/race.gd`) | Valor | Por qué |
| --- | --- | --- |
| `camera_distance_stopped_m` → `camera_distance_fast_m` | 11,4 → 7,2 m | lejos para maniobrar, cerca para correr |
| `camera_height_stopped_m` → `camera_height_fast_m` | 3,45 → 2,70 m | mantiene el ángulo de anticipación al acercarse |
| `camera_ahead_stopped_m` → `camera_ahead_fast_m` | 11,0 → 24,0 m | al ir cerca hay que mirar más lejos para no perder la pista |
| `camera_tau_closing` / `camera_tau_opening` | 0,55 / 0,85 s | acercarse es inmediato; alejarse, progresivo |
| `camera_tau_yaw` / `camera_max_yaw_lag_rad` | 0,20 s / 0,44 rad | la cámara se queda un poco por fuera en curva, acotado |
| `camera_min_distance_m`, `camera_wall_margin_m` | 3,6 m / 0,35 m | anticolisión: nunca dentro del coche |
| `camera_squeeze_ratio` | 0,25 | si un muro obliga a acortar, la cámara baja en la misma proporción |
| **FOV** | **72°, fijo** | no se toca: el acercamiento es distancia real, no encuadre |

Resultado, medido en **dos instrumentos independientes** (caja del modelo proyectada con
la cámara y silueta contada en píxeles sobre las capturas): de parado a 200 km/h la
distancia pasa de 11,39 a 7,20 m y el coche **crece de 155 a 298 px de alto (factor
1,92)**; con la cámara anterior encogía de 219 a 89 px (factor 0,41). La frenada es
monótona (7,20 → 7,37 → 7,88 → 8,63 → 11,38 m), sin oscilaciones, con salto máximo de
0,017 m por fotograma, 0 cambios de sentido, el coche siempre entero (margen mínimo
80 px a 200 km/h) y la trazada a 20/40/60 m por delante dentro del cuadro en los 13
casos. Galería comparativa:
[`comparativa.html`](.tools/recovery/fase-camara/comparativa.html).

### 11.2 Estado del artefacto (15 de octubre, 01:37)

`./verify.sh` en la corrida final (AVD `PRO`/Pixel 9a, `emulator-5556`, lienzo horizontal
**2424×1080**): **38 comprobaciones, 0 fallos obligatorios, 0 omitidas** (`resultado: OK`,
código de salida 0), con la sonda de la cámara, la auditoría de píxeles del anfitrión y las
dos comprobaciones **nuevas** del dispositivo (`camara_dispositivo` y `camara_pixeles`)
entre las obligatorias. APK recompilado, firmado, instalado y comparado (el `base.apk`
extraído del aparato es idéntico):

| Artefacto | Bytes | SHA-256 |
| --- | --- | --- |
| `build/android/F1OneShot-BarcelonaMoto.apk` | 247 695 969 | `bb7d907c46a25a604f0b8b18ef7bee9a9b8b875794180f1280163eaa2b65dbc6` |
| `assets/BarcelonaMoto-Tutorial.glb` | 188 646 600 | `d9ceb75798958c8090eff9223230b9cb56b0e56e0491405b8b89c968f6fd7c06` |
| `assets/RedBull-Drive.glb` | 26 595 516 | `a1d3f7ff073bd9bb33ae6f3050b08db3c74a04e1fc0a5e3524b860a9681d0c8a` |

Circuito y coche conservan su huella: la única fuente de juego que cambia en esta fase es
`scripts/race.gd`. Rendimiento del anfitrión (1280×720, 600 fotogramas): **76,0 fps** en la
corrida final, 75,9 antes de la fase y 79,8 en la primera corrida de la fase —la horquilla
entre corridas de la misma sonda es del 5 %, y lo que dicen las tres medidas es que la
cámara nueva **no cuesta fotogramas**—.

El APK cambia de huella en cada corrida porque Godot no produce un archivo reproducible byte
a byte (mismo contenido, distinta marca de tiempo del ZIP): las 38 comprobaciones de esta
corrida se hicieron sobre el APK de esta corrida, con la huella del instalado contrastada
contra la del compilado.

### 11.3 Cámara medida en el dispositivo, conduciendo con toques reales

La comprobación está en `verify.sh` como **obligatoria** (sección 9): relanza el juego,
conduce con toques reales sobre los pedales y captura la pantalla mientras acelera y
frena; la velocidad de cada captura se lee de la **barra del HUD** en la propia imagen.
Resultado en el emulador:

Las 16 capturas de la corrida final (acelerando, y después frenando; después de cada
pisotón el criterio no exige la velocidad pedida, ordena lo que el juego pintó):

| velocidad (HUD) | coche en pantalla | observación |
| --- | --- | --- |
| 0,0 km/h | 126 px · 11,7 % del alto | parado en la salida (3 capturas idénticas) |
| 37,7 km/h | 130 px · 12,0 % | |
| 95,4 km/h | 152 px · 14,1 % | |
| 156,0 km/h | 185 px · 17,1 % | ver la dispersión declarada abajo |
| 154,0 km/h | 205 px · 19,0 % | |
| 195,7 km/h | 225 px · 20,8 % | |
| 233,4 km/h | 247 px · 22,9 % | |
| **261,3 km/h** | 245 px · 22,7 % | tope de la ley (198 km/h) ya alcanzado |
| 252,3 km/h (frenando) | 242 px · 22,4 % | la cámara se aleja al frenar |
| 144,0 km/h (frenando) | 230 px · 21,3 % | |
| 7,0 km/h (frenando) | 162 px · 15,0 % | |
| 0,0 km/h (frenando) | 133 px · 12,3 % | |
| 0,0 km/h (parado final) | 124 px · 11,5 % | vuelve al tamaño de la salida |

La comprobación compara **un escalón de 50 km/h con el siguiente** (eligiendo la captura
acelerando más cercana a 0, 50, 100, 150 y 200 km/h): 126 → 130 (+3,2 %) → 152 (+16,9 %) →
205 (+34,9 %) → 225 px (+9,8 %). De parado al escalón más alto el coche crece **1,79×**
(criterio ≥ 1,45) y nunca queda cortado (margen mínimo 176 px de los 8 px exigidos).
Cuatro cosas que van con la entrega:

1. **El coche llega a 261,3 km/h** en la recta principal con el acelerador a fondo (la
   curva de aceleración es física: pasos de 57,7, 58,6, 41,7, 37,7 y 27,9 km/h,
   decrecientes), así que el «200 km/h» de la sonda del anfitrión es lo que su lazo de
   control **mantiene**, no el techo del coche. El tope de la ley de la cámara (198 km/h →
   7,20 m) es por tanto un límite declarado, y quien lo comprueba es el anfitrión (189,7
   km/h → 7,38 m, 198,4 km/h → 7,20 m exactos): en el aparato, de 195,7 a 233,4 km/h el
   coche todavía crece un 10 % y de 233,4 a 261,3 encoge un 0,8 %, dentro de la dispersión
   del propio instrumento (punto 3).
2. **La medida de píxeles del teléfono es una medida de tendencia**: sin fotograma sin
   coche, la silueta la saca el clasificador de librea (validado contra la diferencia
   real en las capturas del anfitrión con ≤ 3,4 % de error), y en el teléfono agrupa el
   cuerpo oscuro y deja fuera la parte alta más clara, midiendo ~20 % menos que la
   diferencia de fotogramas a la misma distancia. Por eso el número absoluto del aparato
   no se compara con el de la sonda y sí la tendencia; la comparación absoluta se hace en
   el anfitrión, sobre el mismo lienzo (2400×1080; el aparato da 2424×1080 y el HUD escala
   con la altura, idéntico en ambos).
3. **La dispersión del aparato a la misma velocidad es del 11 %**: `disp-007` y `disp-008`
   son dos capturas consecutivas con la barra en 156,0 y 154,0 km/h (1 px ≈ 1 km/h, y las
   dos lecturas son tramos continuos, no es el lector) y el alto medido difiere un 11 %;
   parado, las tres capturas dan 126/126/126 px (0 %). Queda declarado y no atribuido con
   certeza. Es la razón de que la comprobación mida un escalón cada 50 km/h y afirme la
   **tendencia**, no cada captura.
4. **Dos defectos del instrumento que encontró la propia batería** y que se arreglaron sin
   tocar el juego ni relajar el criterio: la medida del teléfono elegía la mancha más
   grande, y en `disp-006` el **césped** le ganaba al coche por 132 px (15 077 contra
   14 945) —ahora la mancha se elige por la **librea azul oscura del chasis**, y la
   validación no se movió: 3,4 % de peor desvío—; y la comprobación de orientación exigía
   `ROTATION_90`/`270` cuando este AVD declara `mLandscapeRotation=ROTATION_0`, con la
   ventana ya perfectamente horizontal y a pantalla completa. La corrida que falló por esto
   queda archivada (`.tools/recovery/logs/bateria-1-fallo-pantalla.log`), y los cuatro
   volcados retorcidos con los que se probó el arreglo siguen fallando.

Además, el script comprueba el **foco** con `dumpsys window` antes de arrancar y antes
de cada pisotón y **se para** si el primer plano no es este juego: el emulador es un
aparato compartido y el primer intento se abortó porque otra aplicación lo ocupaba.

### 11.4 Cómo se reproduce esta fase

```bash
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --path . -s scripts/camera_probe.gd              # cámara nueva: mide y verifica
$G --path . -s scripts/camera_probe.gd -- legacy     # cámara anterior, mismo instrumento
python3 .tools/recovery/camera_pixels.py medida .tools/recovery/fase-camara   # resta de fotogramas
python3 .tools/recovery/camera_pixels.py valida .tools/recovery/fase-camara   # cuánto miente el clasificador
python3 .tools/recovery/fase-camara/galeria.py       # galería antes/después
# en el dispositivo (necesita el emulador libre y con el juego en primer plano)
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/fase-camara/capturar_dispositivo.py \
    emulator-5556 .tools/recovery/integral/shots/camara --size 2424x1080
python3 .tools/recovery/camera_pixels.py dispositivo .tools/recovery/integral/shots/camara
```

---

## 12. Fase: cámara del morro (segunda vista jugable) y su botón

Informe completo y reproducible: `.tools/recovery/fase-fp/INFORME-FASE-FP.md`.

### 12.1 Qué se ha añadido

- **Segunda cámara jugable en primera persona**, en el morro del Red Bull, con su
  propio nodo (`race.nose_camera`) y sus propios parámetros. El punto de vista sale
  de los hitos **medidos** del modelo entregado, no de coordenadas inventadas:
  eje delantero z = −1,511 m, alto del neumático y = +0,748 m, techo de la
  carrocería y = +1,232 m.
- **Botón de cambio de vista** en el HUD (`Camera switch`), arriba a la derecha,
  anclado al borde derecho, que dice qué cámara está puesta. Se comprueba contra
  los rectángulos reales del mando, los pedales y los dos paneles: cero solape.
- **Cambio de vista** con arco y transición de 0,22 s: la cámara que entra nace
  donde estaba la que sale (medido: 0,071 m y 0,082 m, que es el primer paso del
  arco a 120 Hz), sin detener ni reiniciar la carrera.

### 12.2 Parámetros finales de la cámara del morro

```
x = 0,00 m                        (centro del coche)
y = alto del neumático + 0,26 m   → +1,011 m
z = eje delantero      + 0,30 m   → −1,211 m
inclinación hacia abajo 17°   ·   campo de visión 74°   ·   plano cercano 0,1 m
holgura medida con el techo de la carrocería en su vertical: 0,225 m
```

Declarados como `@export` en `scripts/race.gd` (`@export_category("Nose camera")`).

### 12.3 Lo que se midió (y con qué)

| Medida | Instrumento | Resultado |
|---|---|---|
| Composición en píxeles contra la referencia aprobada | `.tools/recovery/fase-fp/morro_pixeles.py` | franja del coche 0,32–0,34 en seis situaciones (referencia 0,43, banda 0,25–0,61); centro x 0,50 en las seis; cada neumático 0,61–1,48 % del lienzo (mínimo 0,5 %) y su borde interno en los cuartos laterales (0,17–0,25 el izquierdo, 0,76–0,84 el derecho); las dos reglas de silueta del medidor coinciden en las seis (difieren 0,0000) |
| Rigidez respecto al coche (que no se aleje al correr) | `scripts/camera_nose_probe.gd` | deriva máxima 0,0001 m y salto máximo 0,0001 m por fotograma, de parado a 195 km/h |
| Holgura con el carenado (que no lo atraviese) | igual, contra el perfil real de la malla del chasis | 0,225 m en el punto de vista; 0,225 m y 0,269 m durante el cambio de vista |
| La carrera no se detiene | igual | cronómetro monótono y avanzando, vueltas intactas, coche avanzando lo que le toca (25,1 m a 160 km/h) |
| Cambio de vista con toques reales | `.tools/recovery/fase-fp/capturar_morro_dispositivo.py` | morro a 194 km/h: 0,419 de coche en la caja inferior central y horizonte al 11 % del alto; persecución 0,007 y 0,004 con horizonte al 28–31 %. Cronómetro `00:08.242 → 00:15.667` y el coche subiendo 164 → 197 km/h después del cambio con el pedal pisado |

**Dos errores de medida se encontraron por el camino y se corrigieron** (los dos
daban un número creíble y falso): el alto del neumático medido a través del giro
de la rueda (0,748 m con la rueda en cruz y 0,52 m a 45°, porque una caja girada
proyecta otra caja) y la composición juzgada proyectando vértices pegados al plano
cercano (21 anchos de lienzo con el encuadre correcto). Se miden por el buje más
el radio de la malla, y en píxeles, respectivamente.

**Un fallo real de la transición**: el arco se media con el avance suavizado
(`smoothstep`) y al 15 % del cambio sólo había subido el 6 % de la altura, así que
la cámara pasaba 2 cm **por dentro** de la toma de aire al volver a la persecución
(holgura −0,019 m). Ahora el arco usa el progreso lineal.

### 12.4 Límites conocidos

- La visibilidad del neumático depende del **giro de la dirección**: con las ruedas
  giradas uno enseña mucho más flanco que el otro (25.807 px frente a 15.465 px en
  la frenada). Los dos se ven siempre, pero la simetría perfecta de la referencia no
  se da en todas las situaciones.
- El horizonte **se tumba** con el balanceo del chasis en curva, igual que una
  cámara montada en el morro de verdad. No se corrige: hacerlo sería alterar la
  actitud del coche para un efecto visual, que es lo que el encargo prohíbe.
- El cambio de vista está medido a 160 km/h en recta; contra un muro pegado no se
  ha muestreado (la anticolisión de la persecución acorta su recorrido).
- Las fotografías de la composición en la curva se toman con el coche **detenido en
  el mismo punto del viraje** (el escenario se mide antes, conduciendo). A velocidad,
  cuánto neumático delantero enseña la cámara no es reproducible —el mismo neumático
  sale con 51 377 px en una pasada y con 10 049 px en otra, mismo viraje y misma
  velocidad, con la suspensión dentro de su recorrido, sin topar y con 0,03° de
  dirección— y la composición no depende de eso, porque la cámara es rígida. Detenido
  en el mismo punto, el estado se repite al 2 %. El motivo está en la sección 13.5 y
  los números en el comentario de `CURVA_ASENTAMIENTO_DETENIDO_S`.

### 12.5 Cómo se reproduce

```bash
./verify.sh                                  # incluye sonda_morro, audit_morro y morro_dispositivo
# sólo esta fase, en el anfitrión
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --path . -s scripts/camera_nose_probe.gd  # mide y guarda capturas + morro.json
python3 .tools/recovery/fase-fp/morro_pixeles.py                 # composición en píxeles
python3 .tools/recovery/fase-fp/hoja_de_contacto.py              # hoja de contacto
# en el dispositivo (necesita el emulador libre y con el juego en primer plano)
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/fase-fp/capturar_morro_dispositivo.py \
    emulator-5556 .tools/recovery/integral/shots/morro --size 2424x1080
```

## 13. Fase: los muros invisibles de la calzada

Informe completo y reproducible: `.tools/recovery/fase-muros/INFORME-FASE-MUROS.md`.
Copia de recuperación anterior a tocar nada:
`.tools/recovery/fase-muros/backup-20261015-1230` (`shasum -a 256 -c SHA256SUMS`).

Los dos vídeos del encargo (`9879.mp4` y `9880.mp4`) muestran el coche clavándose
sobre el asfalto a más de 200 km/h sin que se vea nada delante. La causa era una
malla de **física** del circuito original de Assetto Corsa —relieve del suelo, no
suelo ni muro— que sobresale hasta 9 cm del asfalto y **no está dibujada**.

### 13.1 El síntoma, medido en los vídeos

Medidos fotograma a fotograma con `.tools/recovery/fase-muros/video_audit.py`
(velocidad de la barra del HUD, mando y pedales, con la geometría del lienzo):

| vídeo | máximo | suceso | antes | después | g | después del golpe |
|---|---|---|---|---|---|---|
| 9880 | 244,4 km/h | t=17,057 s | 241,4 km/h | 0,0 km/h | 408,8 | 6,47 s a ≤10,4 km/h con el acelerador a 0,23–0,65 |
| 9879 | 211,6 km/h | t=14,943 s | 107,3 km/h | 55,1 km/h | 88,2 | — |
| 9879 | 211,6 km/h | t=33,956 s | 208,6 km/h | 134,1 km/h | 42,0 | 5,81 s a 0 km/h con el acelerador a 0,50 |

En los dos vídeos el mando va centrado (en reposo en 1230 de 1409 y en 2112 de 2400
lecturas): van en recta. Un coche de 241 km/h que pasa a 0 en un fotograma, sobre
asfalto y sin nada delante, es un muro invisible.

### 13.2 Qué había en el circuito

La malla de física trae grupos que en Assetto Corsa **no son suelo ni muro, sino
relieve del suelo**: `MARBLES` (goma de rueda), `BUMP` (badenes), `GRILLE`
(rejillas), `TRAV` (cruces) y `CNCPTS` (escalones de hormigón). En AC no molestan
porque su coche son cuatro rayos de rueda; aquí el coche es una caja rígida contra
una malla trimesh, así que un escalón es un muro, y como las mallas de física no se
dibujan, el muro es invisible.

Medido sobre la geometría tal como la entrega AC (`relief_probe.gd -- --original`):
**865 de las 16 668 caras** de relieve sobresalen más de 5 cm del suelo que tienen
justo debajo, la peor **+0,09 m**. Y no tienen nada dibujado alrededor: con
`visual_cover_probe.gd`, que raya alrededor de cada cara contra las mallas
**visibles**, **244 caras sobresalen sin nada dibujado a menos de 25 cm**.

### 13.3 La corrección

En `scripts/race.gd`, `_hundir_relieve_de_calzada()` desplaza hacia abajo la forma
de colisión de los **cinco cuerpos** de esos grupos, `RELIEF_SINK_M = 1,5 m`. No se
toca ninguna otra colisión (ni muros, ni vallas, ni guardarraíles, ni bordillos, ni
las superficies de la pista) ni ningún material. El 1,50 m sale de la medida: la
cara más alta sobresale +0,09 m, así que todas quedan al menos 1,41 m por debajo del
asfalto. El arranque no paga nada (es un desplazamiento de formas, no consultas al
espacio: `relief_flatten_check.gd`), a diferencia de la versión que medía cara a cara
con un rayo por vértice, que tardaba más de siete minutos.

### 13.4 Lo que se midió (y con qué)

| Medida | Instrumento | Resultado |
|---|---|---|
| Ninguna cara de relieve por encima de la calzada | `scripts/relief_probe.gd` (obligatoria) | 16 668 caras medidas contra su suelo; 0 por encima del tope de 5 cm; la más alta, 1,41 m por debajo |
| Nada más se ha movido | igual, montando otra vez el `GLB` sin la escena y comparando cuerpo a cuerpo | 16 cuerpos en su sitio (0,00 m); los 5 de relieve hundidos exactamente 1,50 m |
| El coche no se clava a fondo en la recta | `scripts/straight_run_probe.gd` (obligatoria) | 313,5 km/h máximo; pasa las estaciones 408 / 462 / 518 a 295,0 / 302,0 / 310,3 km/h sobre `TRM-BRC` con las cuatro ruedas; sólo se detiene 55,1 m fuera de la trazada, sobre arena |
| La causa, probada en el mismo binario | igual, con `--relieve-como-antes` (devuelve el relieve a su altura original) | el coche **se clava sobre el asfalto**: se detiene en la estación 549, a 4,84 m de la trazada, tras alcanzar 313,5 km/h, y en 3 s más con el acelerador a fondo sólo avanza 8,75 m, contra el cuerpo `MARBLES` |
| La velocidad de los vídeos, reproducida dentro del juego | `scripts/video_replay_probe.gd` (obligatoria) | 9880: 237,4 km/h y estación final 504 sin clavarse, y en el instante del choque del vídeo 231,6 km/h sobre `TRM-BRC` con cuatro ruedas; 9879: 204,8 km/h y estación 503, atravesando sus dos zonas de choque a 103,9 y 203,7 km/h sobre asfalto |
| Arranque del hundimiento | `scripts/relief_flatten_check.gd` | la escena entera arranca en 5,63 s y el hundimiento son 5 desplazamientos de forma: no añade ninguna consulta al espacio |
| Las dos zonas de los vídeos, **en el APK instalado** | `.tools/recovery/fase-muros/recto_device_check.py` | acelerador a fondo y sin dirección: 0 → 303,0 km/h (31,8 / 119,2 / 204,6 / 257,3 / 293,0 / 295,0 / 303,0 km/h cada 2 s), cruzando las tres velocidades de los choques —107,3, 208,6 y 241,4 km/h— **sin detenerse**; sin congelados con el coche rodando (7 intervalos, mínimo 0,249); sólo se para al salirse al final de la recta. Deja 15 capturas, la traza del HUD y `recto-device.mp4` |
| Conducir fuera del asfalto en el APK instalado | `.tools/recovery/offtrack_device_check.py` | PASS: el coche sigue rodando fuera de la pista, con la imagen cambiando en los 10 intervalos de la rodadura (mínimo 0,074) y sin errores en el registro del dispositivo |
| Vuelta completa conduciendo | `scripts/driving_probe.gd` (obligatoria) | 528,3 s, **0 golpes contra muros**, 2,37 m de error máximo respecto a la trazada y nunca menos de dos ruedas apoyadas (14 fotogramas de vuelo) |
| Todo el proyecto, incluido el dispositivo | `./verify.sh` | **46 comprobaciones, resultado `OK`, 0 fallos obligatorios y 0 omitidas**; incluye el APK firmado, la instalación sin incremental y la huella del APK instalado, idéntica a la del compilado (`3b696574520d105afec63a073128c71d24c8acafc8caef7f7a43adc43bdf121c`) |

### 13.5 Un caso que estaba pasando por el defecto

La sonda de la cámara del morro medía su caso «curva» **con el coche detenido por el
relieve**: sostenía 130 km/h en el viraje más cerrado del trazado (radio 30 m, que a
esa velocidad pide ~3,8 g) y el coche acababa fuera, dentro de la barrera; el listón
aprobado de esa fase estaba midiendo el defecto. Se ha arreglado el **escenario**, no
el criterio: la curva se conduce por el viraje **más cerrado que el coche puede tomar
a 130 km/h** con un límite de agarre declarado (0,9 g) y el caso exige ahora que el
coche **siga en calzada y a ≤4 m de la trazada** al medir la composición. Medido:
121,1 km/h por el viraje de radio 148 m, 0,27 g pedidos, 0,27 m de la trazada, sobre
`TRM-BRC`. La banda de píxeles (0,25–0,61 del alto) no se ha tocado: la franja medida
es 0,32.

El escenario necesitó dos correcciones. La primera conducía a la velocidad que permite
el viraje de radio 30 m (41 km/h, 0,4 g) y ahí salió un segundo problema del mismo
caso: con la dirección tan girada, uno de los neumáticos delanteros queda tapado por
la carrocería —medido: 9 269 px, 0,36 % del lienzo, por debajo del 0,5 % que el caso
pide—, así que esa composición no puede darse en un viraje así.

La versión final conduce el viraje —121,1 km/h, radio 148 m, 0,27 g, 0,27 m de la
trazada— y toma las fotografías con el coche **detenido en el mismo punto**: a
velocidad, el trozo de neumático delantero que enseña la cámara no es reproducible
(el mismo neumático, 51 377 px en una pasada y 10 049 px en otra, mismo viraje y misma
velocidad, con la suspensión dentro de su recorrido, sin topar y con 0,03° de
dirección), y la composición no depende de eso porque la cámara es rígida respecto al
coche. Detenido en el mismo punto, el estado se repite al 2 % (dos pasadas: 35 372 y
35 876 px en el neumático izquierdo). La franja del coche queda en 0,32 y los dos
neumáticos a la vista (1,07–1,38 % del lienzo), como en las otras cinco situaciones;
y la regla del color pintado vuelve a valer también en la curva, así que las seis se
miden igual y el medidor **exige** que las dos reglas coincidan.

### 13.6 Límites

- De las 16 668 caras de relieve, **1 550 no tienen suelo que medir** (el rayo no
  encuentra superficie: quedan sobre un hueco o dentro de otra geometría) y quedan
  fuera de la medida cara a cara. El caso que importa —el coche pasando por encima a
  fondo— lo cubren la prueba de recta y la reproducción de los vídeos.
- El hundimiento es una constante, justificada por la medida y comprobada en cada
  pasada por `sonda_relieve`; no se mide en tiempo de ejecución.
- El relieve no se ha retirado: sigue ahí, debajo de la calzada.
- La pasada del aparato mide la velocidad en la barra del HUD (allí no hay sonda
  interna) y juzga hasta la mayor de las tres velocidades de choque de los vídeos;
  cruzada esa velocidad, lo que sigue es salirse de la pista y se informa, no se
  juzga.
- Las dos comprobaciones del aparato no están dentro de `./verify.sh` (necesitan el
  emulador libre y la batería lo ocupa en su propia fase de dispositivo): se ejecutan
  con los comandos de la sección 13.7.

### 13.7 Cómo se reproduce

```bash
python3 .tools/recovery/fase-muros/video_audit.py ~/Downloads/9880.mp4 ~/Downloads/9879.mp4 \
    --salida .tools/recovery/fase-muros/videos --fotogramas .tools/recovery/fase-muros/fotogramas
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --headless --path . --script res://scripts/relief_probe.gd -- --original   # el relieve de AC
$G --headless --path . --script res://scripts/relief_probe.gd                 # el del juego
$G --headless --path . --script res://scripts/visual_cover_probe.gd           # dibujado o invisible
$G --path . --script res://scripts/straight_run_probe.gd                      # recta a fondo
$G --path . --script res://scripts/straight_run_probe.gd -- --relieve-como-antes
# en el aparato, con el APK de la entrega ya instalado
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/fase-muros/recto_device_check.py \
    emulator-5556 .tools/recovery/fase-muros/shots/recto-device
ADB=$ANDROID_HOME/platform-tools/adb python3 .tools/recovery/offtrack_device_check.py \
    emulator-5556 .tools/recovery/fase-muros/shots/offtrack-device
$G --path . --script res://scripts/video_replay_probe.gd -- 9880 9879         # los vídeos
./verify.sh                                                                   # todo
```
