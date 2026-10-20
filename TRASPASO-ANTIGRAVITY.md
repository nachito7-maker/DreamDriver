# TRASPASO — F1 One Shot Barcelona (Godot 4.7) → Antigravity / Gemini

Escrito el 16-oct-2026 a las 16:30 por la sesión anterior (Codebuff). Léelo entero: es el
único documento que necesitas para empezar sin auditar nada. Los "informes de fase" que
hay en `.tools/recovery/` siguen siendo válidos; este archivo los resume y los indexa.

---

## 0. Qué es esto y qué NO se puede hacer

Juego de F1 en **Godot 4.7 (GDScript)**: un solo circuito (Barcelona-Cataluña, layout
**motos**, sin chicane final), un monoplaza Red Bull, cámara de persecución, controles
táctiles, HUD, cronómetro y APK de Android. Todo el proyecto está medido con **sondas**
(scripts que devuelven código ≠ 0 si algo falla).

Restricciones del encargo, vigentes:
- No rehacer el proyecto ni cambiar de motor.
- No tocar circuito, cámara, línea de asistencia ni interfaz sin causa demostrada.
- **No borrar correcciones previas para que pase una prueba**, ni ocultar fallos heredados,
  ni omitir pruebas sin decirlo.
- No declarar resuelto algo por compilar: hacen falta números reproducibles.

Trampa nº 1, la más importante: **este proyecto NO tiene repositorio git** (`git status`
falla con "not a git repository"). Las copias se hacen a mano en `.tools/recovery/...`.
Antes de tocar `scripts/car_controller.gd` o `scripts/wheel_suspension.gd`, cópialos.

---

## 1. Primer cuarto de hora (comandos exactos, copiables)

```bash
cd /Users/indenova/AndroidStudioProjects/F1Godot
GODOT=".tools/godot/Godot.app/Contents/MacOS/Godot"

# 1) Una sonda suelta. Las que dibujan/capturan necesitan ventana (sin --headless):
"$GODOT" --path . --script scripts/suspension_probe.gd
"$GODOT" --headless --path . --script scripts/understeer_probe.gd

# 2) Batería de sondas del anfitrión (~21 min, resumen al final):
bash .tools/recovery/run-host-probes.sh && cat /tmp/probes-summary.txt

# 2-bis) Sólo las tres sondas que fallan hoy (~5 min, resumen al final):
bash .tools/recovery/run-failing-probes.sh && cat /tmp/probes2-summary.txt

# 3) Batería oficial completa (sondas + auditorías + APK + emulador, ~9 min de reloj):
./verify.sh                      # SKIP_LONG=1 / SKIP_HOST=1 / SERIAL=emulator-5556
#   resultado por comprobación:  .tools/recovery/integral/checks.tsv
#   informe JSON:                .tools/recovery/integral/verificacion-integral.json
#   registro de cada comprobación: .tools/recovery/integral/logs/<id>.log
```

- **Una sonda a la vez** si dibuja: Godot abre ventana y compite por la GPU con el
  emulador. Las `--headless` sí se pueden encadenar.
- Emulador/APK: paquete `com.freebuff.f1oneshot.barcelonamoto`, APK
  `build/android/F1OneShot-BarcelonaMoto.apk`, serial por defecto `emulator-5556`.
  Usa siempre el adb del SDK (`$ANDROID_HOME/platform-tools/adb`); mezclarlo con el de
  Homebrew rompe el servidor compartido del equipo.
- `.tools/recovery/run-host-probes.sh` es la batería rápida sin dispositivo (la que se usó
  en la sesión anterior); `verify.sh` es la oficial y la única que vale para entregar.

---

## 2. Estado a 16-oct-2026 16:30 — lo primero que hay que saber

Batería del anfitrión lanzada a las 15:56 (13 sondas). Logs completos en
`.tools/recovery/entrega-20261016/bateria-host-1556/` (resumen en `resumen.txt`):

| sonda | resultado | nota |
|---|---|---|
| track, runtime, car_wheel, controls, lap, steering, collision_inventory, barrier_impact | **ok** | sin cambios |
| offtrack_mobility (322 s) | **ok** | el coche se recupera fuera de pista |
| **driving_probe** (vuelta completa, 534 s) | **ok** | la vuelta entera se conduce con la física de hoy |
| **surface_grip_probe** (agarre) | **FALLA** (23 s) | «la maniobra recorre superficie fuera del asfalto durante al menos 2 s (15 fotogramas)». Es una **prueba frágil**, no un fallo del coche: ver la nota de §5-ter |
| **suspension_probe** | **PASA** (54 s) | corregido a las 17:20 con el arreglo del plano de calzada (ver §5-ter): sus dos errores han desaparecido |
| **understeer_probe** (subviraje, 223 s) | **1 error de margen** | el trompo, los 3,97 m y los 28 m/s de deriva han desaparecido; queda que el coche pide el **89 %** del recorrido del mando donde el tope es el 85 % (la entrega pedía 69 %) |
| cámara, morro, línea, materiales, relieve, recto, replay, entrega, ruedas-malla | no ejecutadas hoy | las ejecuta `verify.sh`; en la entrega pasaban |

**Batería completa repetida con el arreglo del plano (16-oct, tarde)**: 11 de las 13 sondas
en verde — incluidas `suspension_probe` (0 errores) y `driving_probe` (vuelta completa en
524,19 s, error máximo 2,22 m, sin tocar muro) — y quedan las dos de la tabla
(`surface_grip_probe`, prueba frágil, y `understeer_probe`, 1 margen). Registros en
`.tools/recovery/entrega-20261016/bateria-plano-arreglado/`.

**Lo esencial:** la versión entregada (16-oct 03:20-04:00, logs en
`.tools/recovery/integral/logs/`) pasaba las tres sondas que hoy fallan. Los dos defectos
del encargo (saltos y aceleración irregular) se atacaron en la sesión anterior y hay
evidencia de que mejoraron, pero **a cambio aparecieron esas tres regresiones**. El
subviraje/trompo de la curva rápida es lo más grave y lo primero que hay que resolver.

Comparación directa del mismo criterio, misma sonda, misma velocidad:
- entregado: `SUBVIRAJE PASS en la curva rapida (radio 216 m) a 222 km/h ... se abre 0.25 m
  hacia fuera (tope 2.0 m)` y `deslizamiento lateral máximo 0.28 m/s` →
  `.tools/recovery/integral/logs/sonda_subviraje.log:475-479` (ese registro **no tiene
  ninguna** línea `SUBVIRAJE FAIL`)
- hoy: `se abre 3.97 m` y `28.06 m/s` →
  `.tools/recovery/entrega-20261016/reevaluacion-1620/understeer_probe.log` (reevaluado con
  los archivos de ahora, 16:20-16:30)
- hoy con el arreglo del plano (§5-ter): `se abre 1.32 m`, `deriva 2.55 m/s`, velocidad
  media 219 km/h → `.tools/recovery/entrega-20261016/plano-arreglado/`

**Pista que acotó el fallo:** el banco de subviraje a 60 y 120 km/h **seguía pasando
entero**; sólo fallaba la curva rápida a 222 km/h. Era alta velocidad, no dirección ni
agarre a baja velocidad.

Evidencia de la sesión anterior, toda junta en `.tools/recovery/entrega-20261016/`:
`bateria-host-1556/` (las 13 sondas de hoy con su `resumen.txt`), `reevaluacion-1620/` (las
tres que fallan, medidas otra vez a las 16:20 con los archivos de ahora), `estado-previo/`
(el `car_controller.gd` de antes de la sesión con su diff, y el candidato a
`wheel_suspension.gd` anterior con el suyo) y `restos-sesion/` (el `.bak` y las tres sondas
`tmp_*` que se han sacado de `scripts/`).

---

## 3. Mapa del proyecto (qué es cada cosa)

| Archivo | Qué es |
|---|---|
| `scripts/car_controller.gd` (~830 líneas) | **El archivo clave.** Física del coche: controles, rayos de suelo, motor/caja/frenos, fuerzas longitudinal y lateral, dirección, velocidad, servo de altura, colocación del modelo visual. |
| `scripts/wheel_suspension.gd` (~450 líneas) | **El otro archivo clave.** Las cuatro suspensiones: plano del chasis resuelto por mínimos cuadrados, cargas por rueda, cabeceo/balanceo, topes de recorrido. Lo llama el controlador. |
| `scripts/race.gd` | Monta la escena: pista (GLB), coche (CharacterBody3D + caja de colisión + modelo Red Bull), cámara, HUD, línea de asistencia, cuenta de relieve hundido. |
| `scripts/track_data.gd` | Pista: línea central, clasificación de superficie y agarre por superficie, posición de salida. |
| `scripts/touch_controls.gd` | Mandos táctiles: volante, pedales y su curva de demanda (`pedal_travel_for`, `steering_travel_for`). |
| `scripts/race_hud.gd` | HUD: velocidad, marcha, cronómetro. |
| `scripts/driving_line.gd` | Línea de asistencia: sólo visual, no toca física, cámara ni HUD. |
| `scenes/race.tscn`, `assets/RedBull.tscn`, `assets/BarcelonaMoto-Tutorial.glb` | Escena, coche y circuito entregados. |
| `scripts/*_probe.gd` (41 en total) | Sondas de verificación. Índice en §8. |
| `verify.sh` | Batería oficial (sondas + auditorías + APK + emulador). |
| `.tools/recovery/` | Todos los informes, capturas y evidencias por fases. |
| `ENTREGA-FINAL.md` | Informe de entrega de la versión que está en el APK. |

---

## 4. Cómo funciona la física (lo mínimo para no romperla)

1. El coche es un `CharacterBody3D` con **una caja de colisión** (1,2 × 0,55 × 3,4 m), no
   un vehículo de rayos completo. **El contacto no lo decide la caja**: lo deciden **cuatro
   rayos**, uno por rueda (`_sample_wheel_contacts`). Por eso `is_on_floor()` es falso por
   diseño: la prueba correcta es `wheel_contacts == 4` y `suspension.road[]`.
2. Con las cuatro alturas de asfalto medidas, `wheel_suspension.step()` resuelve por
   mínimos cuadrados ponderados por la rigidez de cada muelle el plano del chasis
   `y = A + B·x + C·z` con equilibrio de fuerzas y de los dos momentos (cabeceo y
   balanceo). De ahí salen `height`, `slope_x` (balanceo), `slope_z` (cabeceo), el
   recorrido `offset[i]` de cada rueda y la carga `load[i]`.
3. El controlador proyecta la base del coche **sobre el plano de la calzada**
   (`_base_de_apoyo`, `_base_de_apoyo(plano)`) y compone ahí la velocidad: por eso subir
   una rampa no cuesta un cos por fotograma. La pendiente la cobra `grade_force`, una vez.
4. Longitudinal: `engine_force` (potencia/velocidad, recortado por `_throttle_grip_limit`
   y por el círculo de adherencia), freno, aerodinámica (`drag_area_m2`), rodadura, freno
   de motor, `grade_force` y tope de punta (`max_forward_speed_ms × _top_speed_factor`,
   ≈313 km/h). Lateral: `lateral_force` acotado por `lateral_limit` (que crece con la
   carga aerodinámica) y `yaw_rate` acotado por la adherencia conseguida.
5. Altura del cuerpo: `_apoyar_sobre_la_calzada()` es un servosistema con referencia de
   velocidad que mantiene el cuerpo sobre el plano medido; **desde la sesión anterior no
   hay asentamiento automático** (`floor_snap_length = 0`) porque peleaba con el servo.
6. Tres cotas nuevas (sesión anterior, ver §5): rechazo de lecturas de asfalto que no son
   calzada, cota de recorrido del chasis y velocidad vertical máxima del chasis.

---

## 5. Qué se cambió el 16-oct (sesión anterior) y qué efecto tuvo

**`scripts/car_controller.gd` — 4 cambios** (diff exacto en
`.tools/recovery/entrega-20261016/estado-previo/car_controller.diff`; el archivo previo a
todos ellos está en la misma carpeta, `estado-previo/car_controller.gd`):

1. `floor_snap_length` **0.65 → 0.0** y fuera la llamada `apply_floor_snap()`. El
   asentamiento automático pegaba el cuerpo al asfalto por su caja de colisión y peleaba
   con el servosistema de altura: costaba ~4 m/s² entre 280 y 310 km/h y dejaba la
   velocidad clavada cerca de 300 km/h con el pedal a fondo. **Es la causa medida de la
   aceleración irregular** (sondas `ride_probe` y `straight_run_probe`).
2. Nuevo `ride_deadband_m := 0.02`: dentro de esa banda el servo **no** manda velocidad
   vertical (el asfalto lleva la altura). Evitaba 1,7 m/s² de aceleración regalada al
   proyectar una velocidad vertical inexistente sobre la rasante.
3. `ride_height_m` **0.02 → 0.01** (el cuerpo va 10 mm más bajo sobre el plano medido).
4. `suspension.step(..., debug_longitudinal_accel, ...)` en lugar de la aceleración medida
   `(v − v_prev)/dt`: la medida llevaba el golpe de cada irregularidad (en un resalto de
   30 mm a 29 km/h un fotograma daba −100 m/s²), descargaba entero el eje delantero, el
   plano quedaba indeterminado con dos ruedas cargadas y una rueda atravesaba el asfalto
   141 mm.

**`scripts/wheel_suspension.gd` — 3 añadidos** (`estado-previo/wheel_suspension.diff`):
rechazo de una lectura que no es calzada (`road_outlier_m`, 15 cm) y re-resolución del
plano sin ella; **cota por recorrido** (paso 5-bis: el chasis no puede separarse del plano
medido más de lo que alcanzan sus ruedas); **velocidad vertical acotada** del chasis
(paso 5-ter, 8 m/s: el chasis es una masa y no sube medio metro en un fotograma).
⚠️ No existe copia previa fiable de este archivo: la de
`estado-previo/wheel_suspension.gd.candidato` es la última anterior a la sesión
(15-oct 02:05) y **puede no ser idéntica** al estado entregado. Si necesitas revertirlo,
hazlo por hunks leyendo el diff, no sustituyendo el archivo.

**`scripts/suspension_probe.gd` — 1 corrección de la PRUEBA** (no del juego): el resalto
de prueba se construía con el asfalto del punto de partida y quedaba **flotando 300 mm**
sobre la calzada (la recta de meta baja ~300 mm en los 12 m que el coche recorre hasta
él), así que medía el canto de una caja en el aire. Ahora la altura se mide en el destino
del resalto.

Evidencia a favor: `driving_probe` (vuelta completa) ✔, `straight_run_probe` y el banco de
relieve (`relief_probe`) ✔, y la cadena de aceleración medida término a término en
`ride_probe`. Precio medido: los 3 fallos de §2. **No está demostrado cuál de los cambios
provoca el subviraje de la curva rápida** — es la primera tarea.

---

## 5-ter. CAUSA RAÍZ DEMOSTRADA de los rebotes, y su arreglo (16-oct, tarde)

**Lo que se midió.** Se instrumentó el coche fotograma a fotograma en la curva rápida
(221 km/h, `choques`, `vy`, altura del chasis, plano de calzada y las cuatro lecturas de
asfalto). El registro está en `entrega-20261016/instrumentacion/curva-inst2.log`:

```
kmh=221 ruedas=4/4 cargadas=2  a=[-11.455, -11.507, -11.496, -11.542]   <- asfalto real: plano (90 mm)
                 calzada=-10.727  altura=-11.649  vy=-12.00  piso=true  choques=2[TRM-BRC]
                 calzada=-12.321  altura=-11.716  vy= +4.00  piso=false choques=0
```

- El asfalto medido por las **cuatro** ruedas es plano y suave (dentro de 90 mm).
- El **plano de calzada que calculaba la suspensión saltaba 1,6 m cada fotograma**
  (−10,73 ↔ −12,32) y con él la altura del chasis (67 mm por fotograma) y la velocidad
  vertical del servosistema (+4 / −12 m/s, sus dos topes).
- La caja de colisión **golpeaba el asfalto en fotogramas alternos** (`choques=2[
  barcelona_remastered_physics_obj__TRM-BRC__physics]`), y los recorridos de las cuatro
  ruedas estaban clavados en sus topes (+35 mm / −30 mm).

**El mecanismo.** `wheel_suspension._solve_plane()` resolvía el plano **sólo con las ruedas
CARGADAS**. En una curva rápida el reparto de carga descarga las dos interiores
(`cargadas=2`), así que el ajuste se quedaba con **dos puntos del mismo lado**: el sistema
3×3 queda casi indeterminado, la altura y las pendientes se reparten esa libertad y el
resultado oscila. Con las cuatro lecturas válidas disponibles, el mal condicionado lo
producía el propio filtro. Este es el origen de los rebotes del vídeo sobre asfalto
aparentemente normal: el plano del chasis se separaba del asfalto y volvía, con las ruedas
siguiéndolo; y es lo que la cota de ayer (paso 5-bis) convirtió en ciclo límite con golpes
contra el asfalto, pérdida de 50 km/h y salida de eje.

**El arreglo** (en `scripts/wheel_suspension.gd`, tres líneas de criterio y sus
comentarios): la **geometría la fijan las ruedas que TIENEN SUELO** (`grounded`), no las
que llevan carga; la carga entra donde corresponde, como el momento que es (el parámetro
`moment_*`). También el descarte de una lectura falsa pasa a mirar las ruedas con suelo.
Una rueda descargada sigue tocando el asfalto y sigue midiendo dónde está; la que no
sostiene el chasis ya no puede mover el plano.

**Antes / después (mismos comandos, misma máquina):**

| medida | entrega | hoy antes del arreglo | hoy con el arreglo |
|---|---|---|---|
| `suspension_probe` | pasa | 2 errores (balanceo y −287,89 mm) | **pasa (0 errores)** |
| curva rápida: apertura | 0,25 m | 3,97 m | 1,32 m |
| curva rápida: deriva lateral | 0,28 m/s | 28,06 m/s (trompo) | 2,55 m/s |
| curva rápida: velocidad media | 218 km/h | 198 km/h | 219 km/h |
| curva rápida: mando necesario | 69 % | 100 % | 89 % (tope 85 %) |
| `straight_run_probe` (defecto nº 2: aceleración) | pasa, punta 313,5 km/h | — | **pasa, punta 313,5 km/h** (idéntico) |
| `relief_probe` | pasa | — | **pasa** (5 cuerpos hundidos 1,50 m, ninguno sin hundir) |
| `driving_probe` (vuelta completa) | pasa | pasa | **pasa** (524,19 s, error máx. 2,22 m, sin muro) |
| `car_wheel_probe` / `steering_probe` / `controls_probe` / `runtime_probe` | pasan | pasan | **pasan** |

Las dos sondas del defecto nº 2 del encargo (aceleración irregular) siguen verdes **con el
mismo número que la entrega** (313,5 km/h de punta, el coche no se queda clavado), así que el
arreglo del plano no ha tocado la cadena longitudinal: lo que cambió fue la altura del chasis
(vertical), no las fuerzas.

**A/B hechos con el plano ya sano** (`.tools/recovery/pruebas-ab/`):

| variante | apertura en la curva rápida | deriva | veredicto |
|---|---|---|---|
| estado actual (banda 20 mm) | 1,32 m | 2,55 m/s | **el mejor** |
| sin banda muerta (término proporcional siempre) | 3,94 m | 27,97 m/s | vuelve el trompo |
| altura de apoyo 0,02 m | 1,32 m | 2,55 m/s | idéntico: el roce de la caja no es el residuo |
| asentamiento automático (0,65 + `apply_floor_snap`) | 4,72 m, acaba en la hierba | 31,53 m/s | empeora |
| transferencia medida fotograma a fotograma | (con el plano roto: 3,97 m) | 28 m/s | descartado |

**Campo abierto**: queda ese 89 % frente al 85 % exigido y el escenario «entrada con el
acelerador» se va 9,2 m afuera (la entrega, 2,5 m). Ya no hay trompo, ni pérdida de
velocidad, ni rebotes.

**Nota sobre `surface_grip_probe`** (para que nadie persiga un fantasma): esa maniobra
coloca el coche mirando **hacia fuera** de la pista (estación 2760, lado −1) y acelera 1500
fotogramas; cuenta los fotogramas con las ruedas sobre algo que no es asfalto y exige ≥120.
En **todos** los estados probados —entrega, hoy y cada variante del A/B— el coche acelera 3 s
(es lo único que tiene registro: 6 líneas `[mando]`, siempre con `ruedas=0`) y luego se
detiene; la diferencia entre 1337 fotogramas (entrega) y 15 (hoy) está en **dónde acaba
tras salirse**, no en el agarre: la misma sonda comprueba, y pasa, que cada superficie
(TRM-BRC, KERB, GRASS, GRAVEL, SAND, OUT, GREEN, CARPET) se informa y se aplica con su
agarre, que es la propiedad que la maniobra quiere verificar. Queda por decidir si se
arregla la maniobra (que coloque el coche ya sobre hierba o grava) o se acepta como prueba
defectuosa: **no está corregido** y hay que decirlo así.

---

## 6. Trabajo pendiente, con las pistas ya pagadas

### (a) Subviraje/trompo en la curva rápida — **CERRADO** el 16-oct por la tarde
Mismo criterio, misma sonda, misma velocidad (222 km/h, radio 216 m): antes se abría
0,25 m con 0,28 m/s de deslizamiento; el trompo (3,97 m, 28,06 m/s) se reprodujo y su causa
resultó ser el plano de calzada mal condicionado (§5-ter), no ninguna de las cuatro
hipótesis de abajo. Con el arreglo: 1,32 m y 2,55 m/s, sin trompo ni pérdida de velocidad.
Se deja aquí el registro de cómo se acotó.

<details><summary>Pruebas A/B originales (se corrieron con el plano todavía roto)</summary>
Prueba de culpables, de una en una, sin tocar nada más (cada una ~4 min):
```bash
cp scripts/car_controller.gd /tmp/cc.bak
# A) devolver SÓLO el asentamiento: floor_snap_length = 0.65 y volver a llamar apply_floor_snap() tras move_and_slide()
"$GODOT" --headless --path . --script scripts/understeer_probe.gd | tail -20
# B) devolver SÓLO la altura de apoyo: ride_height_m = 0.02
# C) devolver SÓLO la fuente de la transferencia: suspension.step(..., acceleration_longitudinal, ...)
```
Hipótesis razonables: (A) sin asentamiento el cuerpo deja de seguir la rasante y la caja de
colisión pasa a decidir el contacto en las combas rápidas; (B) con `ride_height_m = 0.01` el
fondo de la caja (15 mm sobre el origen del cuerpo) puede rozar el asfalto con cabeceo y
balanceo, y ese roce desestabiliza el coche a alta velocidad; (C) el paso 5-ter (velocidad
vertical del chasis acotada a 8 m/s) o el paso 5-bis dejan el chasis por debajo del plano
medido justo en las combas rápidas, y el coche pierde carga. Antes de concluir, compara la
**velocidad y el trazado de entrada** a la curva en los dos logs: los umbrales están
calibrados a 222 km/h y el banco lento pasa entero (ver arriba).

</details>

### (b) «el balanceo de suspensión no se opone al lado exterior» (suspension_probe)
**CERRADO** con (a): era otro síntoma del mismo plano mal condicionado (`a_lat = −16,13 m/s²`
con `roll_relative = −0,726°` y el lado cargado medido al revés). Con el arreglo la sonda de
suspensión termina con 0 errores.

### (c) «garantía estructural: −287,89 mm» (suspension_probe)
**CERRADO** con (a). El paso 5-bis no lo cerraba porque el plano al que recortaba era el
malo; con el plano resuelto por las ruedas con suelo, el criterio
`plano del chasis + recorrido − asfalto medido` queda dentro de tolerancia y la sonda pasa.

### (d) `surface_grip_probe`: maniobra fuera del asfalto — **pendiente, y con el diagnóstico hecho**
No es una consecuencia de (a): da 15 fotogramas en la entrega… no, da 1337 en la entrega y
15 en TODOS los estados de hoy (incluidas todas las variantes del A/B), porque el coche se
detiene a los 3 s de maniobra y la diferencia está en dónde acaba, no en el agarre. Ver la
nota de §5-ter: o se arregla la maniobra (que arranque ya sobre hierba o grava) o se acepta
como prueba defectuosa, **pero no está corregido**.

### (e) Dispositivo
Nada de la sesión anterior se ha probado en el emulador: **el APK instalado sigue siendo el
de la entrega**. Genera APK sólo después de que las sondas del anfitrión estén verdes:
`./verify.sh` completo y clasifica cada fallo como CORREGIDO / REGRESIÓN / HEREDADO /
PRUEBA DEFECTUOSA.

---

## 7. Trampas ya pagadas (no las vuelvas a pagar)

- **No hay git.** Copia a mano antes de editar. `scripts/*.bak` y `tmp_*.gd` de la sesión
  anterior se han movido a `.tools/recovery/entrega-20261016/`.
- **`is_on_floor()` es falso por diseño** (el coche va sobre sus ruedas, no sobre la caja).
  Usa `wheel_contacts == 4` y `suspension.road[]`.
- **El relieve de la calzada está hundido 1,50 m** a propósito (`relief_probe`,
  `relief_flatten_check`): no es un error del circuito, y explica que una prueba que
  compare altura "medida vs. esperada" falle si mide en el punto equivocado.
- **La recta de meta baja ~300 mm en 12 m**: mide cualquier obstáculo de prueba en su
  destino, no donde estás.
- **Los muñones/ muros invisibles y las correcciones de colisiones son intocables**
  (fase 1 de colisiones y fase de muros): hay sondas dedicadas
  (`collision_inventory_probe`, `offtrack_scan_probe`, `barrier_impact_probe`,
  `offtrack_mobility_probe`).
- **adb**: un solo servidor; usa el del SDK y el serial `emulator-5556`. Un corte de un
  segundo hace fallar una instalación sin que el juego tenga nada que ver (por eso
  `verify.sh` tiene `check_reintento`).
- **Las sondas con ventana tapan la pantalla** y compiten con el emulador: de una en una.
- **`.tools/recovery/integral/logs/*.log` (16-oct 03:20-04:00) es la referencia "ANTES"**,
  la mejor que existe: misma máquina, mismas sondas, estado entregado.
- **No declares nada resuelto por compilar** ni por una sonda aislada.

---

## 8. Índice de sondas (qué mide cada una)

En `verify.sh` (obligatorias salvo que se diga otra cosa):
`track_probe` (pista y superficies) · `pbr_probe` (materiales) · `runtime_probe` (arranque,
aceleración y frenada básicas) · `car_wheel_probe` (ruedas y geometría) ·
`suspension_probe` (las 10 pruebas de suspensión — **hoy falla**) · `camera_probe` /
`camera_nose_probe` (cámara, píxeles) · `driving_line_probe` (línea de asistencia) ·
`controls_probe` (controles y multitáctil) · `lap_probe` · `collision_inventory_probe` ·
`offtrack_scan_probe` · `surface_grip_probe` (**hoy falla**) · `steering_probe` ·
`steering_response_probe` · `steer_sign_probe` · `understeer_probe` (**hoy falla**) ·
`offtrack_mobility_probe` · `barrier_impact_probe` · `relief_probe` · `straight_run_probe`
(y su comprobación de causa) · `video_replay_probe` (traza de velocidad de los vídeos del
encargo) · `fps_probe`.

Fuera de `verify.sh`, útiles para diagnosticar: `ride_probe` (banco de pendientes,
vibración y cadena longitudinal término a término), `drive_diag_probe`, `force_probe`,
`contact_face_probe`, `wheel_diag_probe`, `dynamics_probe`, `direct_dyn_probe`,
`line_curvature_probe`, `line_obstruction_probe`, `render_probe`, `loader_probe`,
`api_probe`, `headless_layout_check`.

Sondas de la sesión anterior movidas fuera de `scripts/`: `tmp_bench_probe.gd`,
`tmp_frame_probe.gd`, `tmp_bump_probe.gd` (en `entrega-20261016/`).

## 9. Informes de fase (no repitas estas auditorías)

`.tools/recovery/integral/verificacion-integral.json` (la entrega: todas las
comprobaciones), `ENTREGA-FINAL.md` (informe de entrega), y por fase:
`fase1-colisiones/INFORME-FASE1-COLISIONES.md`, `fase-ruedas/INFORME-FASE-RUEDAS.md`,
`fase2-ruedas/INFORME-FASE2-RUEDAS.md`, `fase3-suspension/INFORME-FASE3-SUSPENSION.md`,
`fase4-resoluciones/INFORME-FASE4-RESOLUCIONES.md`, `fase-muros/INFORME-FASE-MUROS.md`,
`fase-traseras/INFORME-FASE-TRASERAS.md`, `fase-camara/INFORME-FASE-CAMARA.md`,
`fase-fp/INFORME-FASE-FP.md`, `direccion/INFORME-FASE-DIRECCION.md`,
`linea-visual/INFORME-FASE-LINEA-VISUAL.md`, `fase6-subviraje/INFORME-FASE-SUBVIRAJE.md`,
`revert/INFORME-REVERSION.md`, `.tools/touch-fix/INFORME-TOQUE-PEDALES.md`.

## 10. Lo que hay que entregar al final

1. Causa raíz demostrada de los rebotes (la versión entregada; ya hay trabajo hecho: el
   plano del chasis se separaba del asfalto y volvía).
2. Causa raíz demostrada de la aceleración irregular (ya medida: el asentamiento automático
   peleando con el servo de altura; ver §5.1).
3. Archivos modificados y justificación de cada cambio.
4. Resultados de las pruebas antes y después (referencia "antes" en §7).
5. Resultado de `./verify.sh`, con cada fallo clasificado.
6. Ruta y SHA-256 del APK probado.
7. Problemas restantes, sin declarar terminado lo que no esté validado en el dispositivo.
