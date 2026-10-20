# Fase 2 — Auditoría y corrección de las ruedas del Red Bull

Estado: **fase cerrada**. Sólo se ha tocado el coche (modelo y controlador) y las
sondas; circuito, cámara, interfaz, pantalla y física de la pista quedan como estaban.

Copia de recuperación del estado de partida:
[`backup-20261014/`](.tools/recovery/fase2-ruedas/backup-20261014/MANIFEST.md)
(scripts, modelo, medidas del defecto y `SHA256SUMS`). El APK del cierre anterior
(fase 1) era `abc85b2b834a6cd8528eb8574a8bb5105f4790baf33e8cf282bea7c10bfb13e9`.

---

## 1. Qué se auditó

Se midió el coche montado en la escena de carrera, no el código: dónde está el
pivote de cada rueda, hacia dónde gira, a qué distancia del asfalto queda su fondo y
si el conjunto sigue apoyado cuando el coche acelera, frena o gira.

| Prueba | Sonda | Qué mide |
| --- | --- | --- |
| Ruedas en ejecución | `scripts/car_wheel_probe.gd` | pivote, eje de giro, radio, anchura, fondo contra el asfalto, residuo contra el plano de los cuatro contactos, órbita al girar, pose del modelo |
| Entrega (capturas) | `scripts/car_delivery_probe.gd` | el coche parado, en recta a 206 km/h y en curva a 111 km/h, con las mismas medidas en cada situación |
| Activo entregado | `.tools/recovery/audit_delivery.py` | dentro del GLB: fondos de las cuatro ruedas coplanares, pivotes centrados, eje de giro lateral, radios y anchuras, suelo del chasis sobre el plano de contacto |
| Materiales de las ruedas | `scripts/wheel_diag_probe.gd` | qué caras lleva cada material de la rueda (goma / llanta), pintadas en plano |

## 2. Estado de partida medido

Coche parado sobre la calzada, en la recta de meta (peralte 1,48°), sonda en
ejecución del 14 de octubre a las 13:22 (`medidas-antes/probe.log`):

| Rueda | Aire bajo la rueda | Pivote descentrado | Rotación del nodo | Órbita al girar |
| --- | --- | --- | --- | --- |
| delantera izquierda | **−31,5 mm** (hundida) | 11,7 mm | 90° + 180° | 2,0 mm |
| delantera derecha | **+58,0 mm** (en el aire) | 11,2 mm | 90° + 180° | 2,0 mm |
| trasera izquierda | **−69,9 mm** (hundida) | 6,6 mm | 90° + 180° | 2,0 mm |
| trasera derecha | **+17,7 mm** (en el aire) | 6,6 mm | 90° + 180° | 1,9 mm |

Es decir: el coche se apoyaba como un balancín. Entre la rueda trasera izquierda
(7,0 cm metida en el asfalto) y la delantera derecha (5,8 cm en el aire) había
**12,8 cm** de desnivel; y las cuatro ruedas, en vez de girar, describían un círculo
de 2 mm alrededor de su eje (el centro de la malla no estaba en el origen del nodo).

En el activo entregado (`assets/RedBull-Drive.glb`) el mismo defecto está en la
fuente. Medido nodo a nodo sobre el GLB del respaldo, en su espacio de mundo:

| Nodo | Fondo (y) | Ancho | Materiales | Rotación horneada | Superficies |
| --- | --- | --- | --- | --- | --- |
| `Body` | +0,0020 m | 2,153 m | librea | 180° (esperado) | 1 |
| `wheel_fl` | **−0,0065 m** | 0,315 m | librea | 180° sobre (0, 0,7071, −0,7071) | 1 |
| `wheel_fr` | **−0,0069 m** | 0,316 m | librea | idem | 1 |
| `wheel_rl` | **+0,0067 m** | 0,457 m | librea | idem | 1 |
| `wheel_rr` | **+0,0067 m** | 0,458 m | librea | idem | 1 |

Es decir: las cuatro ruedas estaban en tres planos distintos (13,6 mm de dispersión),
cada nodo de rueda llevaba 180° horneados sobre un eje oblicuo, y las cinco mallas
compartían el material de la librea —doble cara, con emisivo y mapa de
metalicidad/rugosidad de la carrocería—, así que la rueda salía como un barril gris
brillante en vez de neumático.

## 3. Causas raíz

1. **Pivote de las ruedas fuera del centro de la malla.** Los cuatro nodos de rueda
   tenían su malla desplazada 6,6–11,7 mm respecto al origen del nodo. Al girar, la
   rueda no rotaba: orbitaba (2 mm por vuelta, y con la rueda girada 90°+180°, el
   descentrado se convertía en bamboleo vertical).
2. **Ruedas no coplanares en el modelo.** En el GLB, los fondos de las cuatro ruedas
diferían hasta 13,6 mm entre sí, así que ningún ajuste de altura podía hacer que
las cuatro apoyaran a la vez: con el chasis apoyado, las delanteras quedaban por
debajo del suelo y las traseras 4,7 mm en el aire.
3. **Rotación horneada en el nodo de cada rueda** (180° sobre (0, 0,7071, −0,7071)):
la rueda estaba girada respecto al coche y el eje de giro no coincidía con el del
nodo, así que `car_controller` le aplicaba la dirección y el giro sobre una base
equivocada.
4. **Pose del modelo invertida.** `_update_visuals` calculaba el cabeceo y el
   balanceo con los dos signos cambiados (`pitch := atan2(-local_normal.z, …)`),
   de modo que el modelo se inclinaba al revés que la calzada: sobre el peralte de
   1,48° de la recta de meta, las ruedas del lado cuesta abajo flotaban y las del
   otro se hundían (de −6,9 cm a +5,9 cm).
5. **Vuelco aplicado al coche entero.** El balanceo y el cabeceo de suspensión se
   aplicaban a `model_root`, que incluye las ruedas. Con ruedas rígidas al modelo,
   eso las separa del asfalto: acelerando a 75 km/h, 3,2 cm por delante y 4,5 cm por
   detrás; en curva a 1,2 g, hasta 8,4 cm en la rueda interior.
6. **Signo del cabeceo invertido.** `_body_pitch = -acceleration_longitudinal ·
0,0035`: al acelerar, el morro bajaba en vez de subir. Medido con el coche
circulando: la carrocería iba 3,2 cm baja delante y 4,5 cm alta detrás.
7. **La muestra de suelo se tomaba antes de moverse.** `_sample_ground()` corre al
   principio del fotograma, antes de `move_and_slide()`, y el modelo se colocaba con
   esa altura: cuesta arriba o abajo, la carrocería iba un fotograma por detrás del
   coche y las ruedas quedaban en el aire en proporción a la velocidad — 2,4–4,1 mm
   a 75 km/h y 13–15 mm a 206 km/h. El filtro vertical de 71 ms añadía su propio
   retardo encima.

Nota de método: la sonda anterior (`probe.log`) conducía escribiendo las meta
`touch_throttle`/`touch_steer`, que la capa de controles de toque reescribe en cada
fotograma; su medida "en marcha" era en realidad del coche parado (velocidad 0,0 m/s
en las dos tandas). Las sondas de esta fase conducen con las entradas reales del mapa
de acciones (`Input.action_press`), que es lo que pisa un dedo.

## 4. Correcciones

| Archivo | Cambio |
| --- | --- |
| `assets/RedBull-Drive.glb` | reprocesado con Blender 5.2 sobre el propio GLB entregado (`.tools/wheels/rebuild_redbull.py`): la rotación de cada nodo de rueda se pasa a la malla, el pivote se lleva al centro de la malla sin mover la rueda en el mundo (0,0000 m), las cuatro se asientan en el plano de contacto (fondo 0,0000 m), el suelo del chasis queda 2 mm por encima, y cada rueda recibe TALÓN medido (percentil 10 del radio de la banda exterior, 0,4528–0,5062 R) dos materiales propios —goma mate y llanta de aluminio cepillado— en vez del material de la librea. No se toca la carrocería, la posición en planta de las ruedas, los nombres de los nodos ni la orientación del coche. Informe: [`.tools/wheels/rebuild-report.json`](.tools/wheels/rebuild-report.json) |
| `scripts/car_controller.gd` | pose del modelo con los signos correctos; el balanceo y el cabeceo pasan a la malla del chasis (masa suspendida) y no al coche entero, con topes de 2°; signo del cabeceo corregido; muestra de suelo repetida tras `move_and_slide()` para el modelo; altura del modelo sin filtro |
| `scripts/car_wheel_probe.gd` | sonda nueva (reescrita): mide lo de §1, **falla con código distinto de cero** si algo no cumple y deja las medidas en JSON |
| `scripts/car_delivery_probe.gd` | sonda nueva: conduce con las entradas reales y captura el coche parado, en recta y en curva, con las medidas de apoyo en cada situación |
| `.tools/recovery/audit_delivery.py` | el activo entregado se audita también por ruedas: fondos coplanares en el plano de contacto, pivote centrado a menos de 1 mm, eje de giro lateral, radios/anchuras y suelo del chasis por encima |
| `verify.sh` | nueva comprobación obligatoria `sonda_ruedas` |

## 5. Medición después

### 5.1 El coche en ejecución (`logs/sonda_ruedas.log`, 14:08)

Las cuatro columnas de medidas van en el orden delantera izquierda · delantera
derecha · trasera izquierda · trasera derecha.

| Situación | Pose del modelo | Aire bajo cada rueda | Residuo contra el plano | Pivote | Orbita |
| --- | --- | --- | --- | --- | --- |
| parado | 0,00° | +0,3 · −0,5 · −6,5 · −5,0 mm | −0,3 · +0,1 · −6,0 · −5,6 mm | 0,0 mm | 0,0 mm |
| en marcha, 75 km/h, 6,49 m/s² | 0,02° | −2,8 · −3,9 · −3,8 · −4,4 mm | −3,0 · −3,9 · −3,8 · −4,7 mm | 0,0 mm | 0,0 mm |

`RUEDAS passed=true errores=0`. Medidas completas: `medidas.json`. Umbrales que
aplica la sonda (declarados en su cabecera): pivote ≤ 1,5 mm, órbita al girar ≤ 1,0
mm, aire bajo la rueda y residuo contra el plano ≤ 12 mm parado y ≤ 30 mm en marcha,
pose ≤ 1,0°, radio 0,30–0,45 m, anchura 0,25–0,55 m. El estado de partida los
incumple en las cuatro ruedas.

### 5.2 El coche en recta y en curva (`logs/sonda_entrega.log`, 14:12)

| Situación | Velocidad | Pose | Residuo de las cuatro ruedas |
| --- | --- | --- | --- |
| parado sobre el asfalto | 0 km/h | 0,00° | +1,8 … +2,5 mm |
| en recta | 206,1 km/h | 0,02° | +0,3 … +3,9 mm |
| en curva (peralte 3,02°) | 111,7 km/h | 0,11° | +0,1 … +4,9 mm |

En las tres situaciones las cuatro ruedas están a menos de 5 mm del asfalto (0,5 mm a
1,3 % del radio de 0,375 m). Antes de la corrección, el mismo coche parado iba de
−7,0 cm a +5,8 cm.

### 5.3 El activo entregado (`audit_entrega` en `verify.sh`)

| Rueda | Fondo | Radio | Anchura | Pivote | Rotación del nodo | Superficies |
| --- | --- | --- | --- | --- | --- | --- |
| `wheel_fl` | 0,0000 m | 0,3808 m | 0,3152 m | (0, 0, 0) | ninguna | 2 (goma + llanta) |
| `wheel_fr` | 0,0000 m | 0,3812 m | 0,3157 m | (0, 0, 0) | ninguna | 2 |
| `wheel_rl` | 0,0000 m | 0,3746 m | 0,4575 m | (0, 0, 0) | ninguna | 2 |
| `wheel_rr` | 0,0000 m | 0,3746 m | 0,4577 m | (0, 0, 0) | ninguna | 2 |

Suelo del chasis: +0,0020 m por encima del plano de contacto. Delanteras de 0,315 m
y traseras de 0,458 m de ancho, que es la proporción de un F1 (la trasera coincide con
la rueda nominal del prototipo, `VehiclePrototypes/wheel/wheel_asset.json`: 0,4608 m).

Comparación del activo, antes (respaldo) y después (entregado):

| | Antes | Después |
| --- | --- | --- |
| Fondos de las cuatro ruedas | −6,5 · −6,9 · +6,7 · +6,7 mm | 0,0000 m las cuatro |
| Pivote respecto al centro de la malla | 11,7 · 11,2 · 6,6 · 6,6 mm | 0,0 mm las cuatro |
| Rotación horneada del nodo | 180° sobre (0, 0,7071, −0,7071) | ninguna |
| Materiales | 1 (librea, compartido con el chasis) | 3 (librea + goma + llanta) |
| Superficies por rueda | 1 | 2 (goma y llanta, repartidas por el talón medido) |

## 6. Capturas de entrega

- [`disparos/hoja-de-contacto.png`](.tools/recovery/fase2-ruedas/disparos/hoja-de-contacto.png)
  — las tres situaciones (parado, en recta a 206 km/h, en curva a 111 km/h) por siete
  puntos de vista, incluida la cámara del juego.
- [`disparos/zoom-ruedas.png`](.tools/recovery/fase2-ruedas/disparos/zoom-ruedas.png)
  — primer plano de la rueda trasera izquierda en las tres situaciones: es donde se
  ve si la goma toca la calzada o queda aire debajo.
- [`disparos/comparativa-antes-despues.png`](.tools/recovery/fase2-ruedas/disparos/comparativa-antes-despues.png)
  — la misma vista de persecución en tres momentos: antes de tocar nada, con la pose
  corregida pero el modelo sin reconstruir, y el estado entregado. Las tres son la
  cámara del juego, pero tomadas en puntos distintos de la recta y con el coche a
  distinta distancia, así que la comparación es cualitativa: lo que decide son las
  medidas de §5, no el encuadre.
- Capturas sin montar: `capturas/` (18 archivos).
- Las vistas auxiliares se toman con el controlador de cámara del juego detenido
  (`race.set_process(false)`) y en coordenadas del coche: `race.gd` reescribe la
  posición de la cámara en cada fotograma y, a 206 km/h, una cámara fija deja al coche
  fuera del encuadre.

## 7. Verificación completa y APK

`./verify.sh` completo (sin `SKIP_LONG`) sobre el árbol final, 14 de octubre de 2026:
**resultado OK, 31 comprobaciones, 0 fallos obligatorios, 0 omitidas**. Registro
[`logs/verify-fase2.log`](.tools/recovery/fase2-ruedas/logs/verify-fase2.log), tabla
[`checks.tsv`](.tools/recovery/integral/checks.tsv) e informe
[`verificacion-integral.json`](.tools/recovery/integral/verificacion-integral.json).

| Grupo | Comprobaciones | Resultado |
| --- | --- | --- |
| 14 sondas de juego (pista, materiales, runtime, **ruedas**, controles, vuelta, inventario, escapatorias, agarre, dirección, sentido, movilidad, impacto, vuelta completa) | 14 | ok (la vuelta completa, 538 s) |
| Auditoría de materiales y del GLB entregado (ruedas incluidas) | 2 | ok |
| Exportación Android, firma y huellas | 3 | ok |
| Dispositivo, instalación, huella instalada, arranque y registro sin errores | 5 | ok (arranque 108 s) |
| Pantalla completa, lienzo y HUD (antes y después de conducir) | 3 | ok |
| Toques reales (acelerador, freno, mando, multitáctil, liberación) y cronómetro | 2 | ok |
| Herramienta de inyección táctil y vueltas por segundo del host (no obligatorias) | 2 | ok |

APK entregado: [`build/android/F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
· 247 667 130 bytes · exportado el 14 de octubre a las 14:30 ·
`sha256 01b2ec6a4496401e89a16bc06741bf0c2d56b86bd9604bfa84c7ab84200b599f`
(la fase 1 cerró con `abc85b2b…`). El `base.apk` extraído del emulador tras
instalarlo coincide byte a byte (`huella_instalada` ok). Tras la última edición se
volvió a exportar el preset y el APK resultante tiene **las 425 entradas idénticas**
(sólo cambian las marcas de tiempo del contenedor), así que lo auditado es el árbol
actual; y la sonda de ruedas se repitió sobre este mismo árbol
([`logs/sonda_ruedas-final.log`](.tools/recovery/fase2-ruedas/logs/sonda_ruedas-final.log),
`passed=true`).

Comprobación visual en el dispositivo: la captura de la propia corrida
([`shots/pantalla.png`](.tools/recovery/integral/shots/pantalla.png), 2400 × 1080) muestra
las cuatro ruedas apoyadas sobre el asfalto de la recta de meta, sin aire debajo ni
rueda hundida.

Rendimiento del host (referencia, no es un teléfono): 66,7–71,8 fps a 1280 × 720 con
la escena completa, frente a los 79,7 fps que anotó la fase 1 en otra sesión. La
segunda muestra de suelo que añade esta fase (4 rayos por fotograma) no cuesta nada
medible: quitándola, 71,2 y 67,8 fps, dentro de la misma dispersión.

## 8. Entrega

| | |
| --- | --- |
| APK | `build/android/F1OneShot-BarcelonaMoto.apk` |
| Tamaño | 247 667 130 bytes |
| SHA-256 | `01b2ec6a4496401e89a16bc06741bf0c2d56b86bd9604bfa84c7ab84200b599f` |
| Huella del APK instalado | idéntica a la del compilado |
| Modelo del coche | `assets/RedBull-Drive.glb` `sha256 9c601ee17243a71248575d2256463de54630416b69ac470427729efcd102aa9f` |
| Corrida `./verify.sh` | OK · 31 comprobaciones · 0 fallos obligatorios · 0 omitidas |
| Estado estable de partida | `.tools/recovery/fase2-ruedas/backup-20261014/` (APK `abc85b2b…`, scripts y modelo) |

Huellas de todo lo que toca esta fase:

```
3149fe1ed1c007b46a1723db71ca7b708863831ce7855d46f230ffa239ce463c  scripts/car_controller.gd
cc826748e7dab9e609db86417143677a13f8879f75d1fc38f1458683479af5ea  scripts/car_wheel_probe.gd
8e805ce810234cf944022690257ae4018b5db9144263ceec578761dfd420b447  scripts/car_delivery_probe.gd
e88d1bcb37e8b22efbf5249bdc34afa58a85749bdf7bb8cb129419e912a2c6fd  verify.sh
711e1974908c1c7c29d27c793d53841c612f6182c0c702c0fff43d2e2e6cb0f1  .tools/recovery/audit_delivery.py
9c601ee17243a71248575d2256463de54630416b69ac470427729efcd102aa9f  assets/RedBull-Drive.glb
```

## 9. Limitaciones pendientes (honestas)

1. Las ruedas son rígidas: no hay suspensión que absorba el peralte ni los badenes.
   El modelo sigue la normal del suelo y el balanceo/cabeceo va sólo en la carrocería,
   así que sobre un badén fuerte (curvatura vertical de pocos metros de radio) alguna
   rueda puede quedar unos milímetros por encima del asfalto; medido en las tres
   situaciones de entrega, el peor caso es 6,5 mm.
2. El suelo del chasis está a 2 mm del plano de contacto. En un peralte fuerte y con
   el coche cruzado, la esquina del fondo puede pasar por debajo de la superficie
   (queda oculta por el asfalto, no se ve aire). No se ha medido el caso peor.
3. `scripts/wheel_diag_probe.gd` pinta las superficies de la rueda para revisarlas a
   ojo (goma / llanta); la comprobación es humana, no automática.
4. Los radios delantero (0,3808 m) y trasero (0,3746 m) difieren en 6,2 mm porque
   provienen del modelo fusionado del prototipo; el diámetro real de un F1 es único.
   Se dejaron como estaban: son los del coche entregado y las cuatro ruedas apoyan en
   el mismo plano.
5. Todo lo medido es del emulador `F1Recovery` (2400 × 1080, GPU host) y del host
   (Apple M1). No hay pruebas en un teléfono físico.

## 10. Cómo se reproduce

```bash
G=.tools/godot/Godot.app/Contents/MacOS/Godot
$G --path . --script scripts/car_wheel_probe.gd      # ruedas, con dientes (código != 0 si falla)
$G --path . --script scripts/car_delivery_probe.gd   # capturas parado / recta / curva
python3 .tools/recovery/fase2-ruedas/hoja_contacto.py  # hojas de contacto y resumen
python3 .tools/recovery/audit_delivery.py            # activo entregado, ruedas incluidas
./verify.sh                                          # batería completa (sondas + APK + dispositivo)
```
