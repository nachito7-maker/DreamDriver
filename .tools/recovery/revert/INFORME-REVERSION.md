# Reversión de la última intervención de DeepSeek

Fecha: 13-oct-2026, 23:00–23:25. Proyecto: F1 One Shot (Godot 4.7.2, Android).

Esta carpeta contiene todo lo necesario para auditar la reversión: copia del estado
anterior, copia del estado que dejó la intervención, registros y capturas.

---

## 1. Resumen

La última intervención (ventana de tiempo **21:44 → 23:00**, APK `ddbf65eb…` exportado
a las 22:07) tocó **8 archivos**: 5 del juego y 3 del arnés de pruebas de dispositivo.
Se han revertido los 5 archivos del juego a la **instantánea previa** del 13-oct 20:48
(`.tools/recovery/stable-before-offtrack-steering/`), que es el último estado conocido
anterior a la intervención, y se han retirado las 3 sondas nuevas que esa intervención
creó. El APK que estaba en `build/android/` (`ddbf65eb…`) se conserva intacto.

El árbol recuperado compila, arranca en el emulador y **dibuja exactamente el mismo
fotograma** que la compilación anterior a la intervención: la captura del APK nuevo es
idéntica byte a byte a `integral/shots/pantalla.png` (19:41) y
`integral/shots/final-apk.png` (15:43).

No se ha introducido ninguna reparación nueva: no se ha tocado la cámara, ni la
dirección, ni las colisiones, ni el circuito.

---

## 2. Qué tocó la última intervención

No hay repositorio Git en el proyecto (`git rev-parse` → *not a git repository*), así
que la atribución se ha hecho con fechas de modificación, la instantánea del 20:48,
los registros de la propia intervención y las huellas de los APK.

| Archivo | mtime | Qué cambió la intervención |
|---|---|---|
| `scripts/car_controller.gd` | 22:55 | Dirección (`steering_at_low_speed_rad` 0.51→0.64, `high` 0.11→0.14, `response` 4.8→5.4, nuevo `steering_sensitivity_multiplier`), nueva física lateral (`lateral_grip_coefficient`, `front_peak_slip_deg`, `understeer_rate/max`) y `_sample_surface_grip` reescrito con un rayo al suelo |
| `scripts/race.gd` | 22:02 | Clasificación de muros importados (metadatos `ac_obstacle`, conteo `native_wall_groups`) |
| `scripts/touch_controls.gd` | 21:58 | Curva del joystick (zona muerta 0.035→0.018, exponente 1.6→0.78) y botón «STEER ×» de sensibilidad |
| `scripts/controls_probe.gd` | 21:56 | Sonda de controles ampliada |
| `scripts/dynamics_probe.gd` | 21:57 | Añadido `car.steering_sensitivity_multiplier = 1.1` |
| `scripts/steering_probe.gd` | — | **nueva** |
| `scripts/barrier_impact_probe.gd` | — | **nueva** |
| `scripts/offtrack_drive_probe.gd` | — | **nueva** |
| `.tools/recovery/AndroidTouch.java` | 22:51 | Fases nuevas del inyector táctil |
| `.tools/recovery/screen_check.py` | 22:51 | Medición de esas fases |
| `.tools/recovery/offtrack_probe.gd` | 22:22 | Auditoría de WALL por metadatos |

`scenes/race.tscn` **no** cambió (misma huella que la instantánea previa).

## 3. Qué se ha revertido

Se restauró byte a byte desde `.tools/recovery/stable-before-offtrack-steering/`:

| Archivo | Huella tras la reversión | Huella que dejó la intervención |
|---|---|---|
| `scripts/car_controller.gd` | `1aee679ce517…` | `a579b3137c2f…` |
| `scripts/race.gd` | `a245da302453…` | `6bda0376050c…` |
| `scripts/touch_controls.gd` | `f94109d49b8d…` | `f85ab9f99572…` |
| `scripts/controls_probe.gd` | `d4d97868a27a…` | `5de1a5fedf82…` |
| `scripts/driving_probe.gd` | `2ddb8fc6adca…` | sin cambios (igual) |
| `scenes/race.tscn` | `81b46924e52d…` | sin cambios (igual) |

Retiradas las tres sondas nuevas (`steering_probe.gd`, `barrier_impact_probe.gd`,
`offtrack_drive_probe.gd`); sus contenidos están guardados en
`backup-20261013-2300/scripts/`.

**Método**: la instantánea `.tools/recovery/stable-before-offtrack-steering/` (creada el
13-oct 20:48, antes de la intervención) es la referencia fiable; se copió cada archivo y
se comprobó la huella. Los APK quedan como referencia cruzada: `8097dc8c…` es el de esa
instantánea, `ddbf65eb…` el de la intervención.

## 4. Lo que no se ha podido restaurar con certeza

Por no existir copia anterior fiable, **no** se ha inventado contenido para:

- `scripts/dynamics_probe.gd` (modificado a las 21:57, sin copia previa). Conserva la
  línea `car.steering_sensitivity_multiplier = 1.1`, propiedad que ya no existe tras la
  reversión: esa sonda fallaría al ejecutarse. Es una sonda de medida, no forma parte
  del juego.
- `.tools/recovery/AndroidTouch.java`, `.tools/recovery/screen_check.py` y
  `.tools/recovery/offtrack_probe.gd` (arnés de pruebas del dispositivo; sin copia
  previa). El último espera el metadato `ac_obstacle` que el `race.gd` revertido ya no
  escribe, así que esa auditoría concreta ya no puede pasar. Ninguno de los tres afecta
  al juego ni al APK.

## 5. Compilación

- Exportación del árbol revertido: `export exit=0`, APK firmado (Godot debug).
- Ruta: `build/android/F1OneShot-BarcelonaMoto.apk`
- SHA-256: `605abf6a160454085636b2146fa8c0d33380b871b1da457b8203a91560dc563c`
  (247 667 130 bytes, 23:17:42)
- Instalado en `emulator-5556` y **verificado idéntico** al compilado
  (`cmp` + SHA-256 de `base.apk` extraído: `605abf6a…`).
- Registro del dispositivo: `[track] tutorial mesh batches=97 original hidden collision
  batches=21` (sin la línea de grupos WALL que añadía la intervención) y
  `[track] Barcelona 2023 Moto layout (no final chicane) | points=3057 | 4611.4 m`.

APK anteriores conservados (no se ha sobrescrito ninguno):
`stable-before-offtrack-steering/F1OneShot-BarcelonaMoto.apk` (`8097dc8c…`) y
`revert/backup-20261013-2300/apk/F1OneShot-BarcelonaMoto-ddbf65.apk` (`ddbf65eb…`).

## 6. Prueba visual

Captura: `shot-apk-recuperado-final.png` (2400×1080), SHA-256
`0cc6a15afa1c90fa1be4b6d0cf8ef9c3ba287412dcbc5c3aedc782888b5d6fb7`.

| Referencia | Diferencia por píxel |
|---|---|
| `integral/shots/pantalla.png` (19:41, previa) | **idéntica** (misma huella) |
| `integral/shots/final-apk.png` (15:43, previa) | **idéntica** (misma huella) |
| `integral/shots/final-hash-screen.png` (19:55, previa) | 1 píxel de diferencia |
| `shots-steering-installed-final.png` (22:27, intervención) | 0,55/255 y solo en un recuadro de 196×60 px de HUD |

Otras comprobaciones sobre el APK instalado:

- `screen_check.py layout` → **PASS**: joystick en (186, 897), pedal del acelerador en su
  sitio, **0 columnas negras** en 2400 columnas.
- Sonda de vista (`vista-final.log`) → **PASS**: cámara a 9,62 m del coche, 3,40 m por
  encima, 9,00 m por detrás, inclinación −20,7°, coche encuadrado (centro, morro y cola
  dentro del lienzo); cielo arriba y asfalto ocupando el 56 % de la mitad inferior.
- La cámara (`race.gd::_build_camera` y `_process`) **no cambió** en la intervención:
  sigue siendo la de persecución, con la misma posición inicial, y ninguno de los
  fotogramas guardados —antes, durante o después— muestra una vista aérea.

## 7. Pruebas de controles y táctiles

En el host, sobre el árbol revertido:

- `track-probe-final.log`: Moto sin chicane final, 3 057 puntos, 4 611,4 m, *spawn* y
  guiñada idénticos a la referencia previa.
- `controls-probe-final.log`: **8 PASS, 0 FAIL** (pedales separados, multitáctil
  acelerador+dirección, curva analógica, retorno al centro, freno solo, recorrido
  analógico, liberación al levantar el dedo).
- `driving-probe-final.log`: el coche conduce con la sonda: 21 muestras, sectores 1→7,
  `valid=true` (no sale de pista ni se atasca).
- `vista-final.log`: vista de conducción correcta (arriba).

En el dispositivo (`touch-regresion.log`, `screen_check.py touch`):

- Joystick: reposo 184–185 → a la derecha 292–294 → vuelve a 191–193.
- Acelerador: cambia la zona de velocidad (2 041–2 815 px) y la marcha (484 px).
- Freno: cambia la velocidad (1 890–2 122 px).
- Presión analógica: acelerador 0,03→0,56; freno 0,21→0,57; liberación analógica
  0,03/0,13.
- **No medidas**: las fases «freno + dirección a la vez» y «liberación total». En las dos
  ejecuciones, las marcas del inyector se cortan en `PHASE end` y nunca llegan
  `PHASE brake_steer` ni `PHASE release`, aunque `AndroidTouch.java` sí las contiene
  (líneas 189–203). Es una limitación del arnés/emulador a ~4,6 fps (las dos
  ejecuciones se cortan en el mismo punto), no un resultado sobre el APK: esas dos
  fases quedan **sin medir**, no falladas.

## 8. Cómo volver atrás

- Al estado que dejó la intervención (APK y scripts): `backup-20261013-2300/`
  (`MANIFEST.md` + `SHA256SUMS`), incluido el APK `ddbf65eb…`.
- Al estado que había antes de empezar a auditar hoy: `estado-antes-de-revertir.png`
  (captura) y las copias de la intervención.
- Al estado estable anterior a la intervención: `stable-before-offtrack-steering/`
  (APK `8097dc8c…` y los cinco guiones).

## 9. Qué no se ha hecho

No se ha rediseñado la cámara, no se ha recalibrado la dirección, no se han tocado las
colisiones, ni el circuito, ni las texturas, ni la iluminación. Las reparaciones que
requieran los hallazgos de la intervención (físicas, colisiones, dirección) quedan para
una tarea posterior, como pedía el encargo.
