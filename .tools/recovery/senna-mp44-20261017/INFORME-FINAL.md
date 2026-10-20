# Informe de conversión e integración — McLaren-Honda MP4/4 de Ayrton Senna

**Proyecto:** F1 One Shot Barcelona Moto (Godot 4.7.2)  
**Fecha:** 17 de octubre de 2026  
**Carpeta de recuperación:** `.tools/recovery/senna-mp44-20261017/`

## Resumen ejecutivo

Se inspeccionó y convirtió el mod suministrado de Assetto Corsa, se preparó en Blender y se integró su vehículo como coche principal del juego sustituyendo la escena/modelo RB. La geometría y los materiales vienen del coche original, no de una reconstrucción: se conservaron la librea y los recursos del skin `12_Senna_R02`, con cuatro ruedas identificadas y presentadas al controlador como pivotes canónicos. Se mantuvo Barcelona Moto sin chicane final, el modo contrarreloj, los controles táctiles, la física existente y sus correcciones.

Se generó un APK nuevo, firmado y empaquetado. Un APK de la compilación preliminar de los mismos cambios se instaló y lanzó satisfactoriamente en el emulador Android 17 `emulator-5558`; sus registros anuncian Barcelona Moto y la captura Android es horizontal. **El APK final de la verificación (hash abajo) no llegó a instalarse:** `verify.sh` perdió el emulador antes de la fase instalación. **No puede considerarse una entrega plenamente validada:** la ejecución integral registró fallos obligatorios de ruedas, suspensión, composición de cámara de morro, auditoría de línea/píxeles, agarre y capacidad lateral. La vuelta completa se omitió explícitamente (`SKIP_LONG=1`). No se rebajaron umbrales.

## Archivo de entrada y seguridad

- Original: [`senna.7z`](AC2026/senna.7z), 123 MiB.
- El archivo siguió intacto; SHA-256: `563c2ef3c75968469b53a0bc70575d2a69fc718ad981b262ab2c424d718c7d5c`.
- El árbol extraído de trabajo se guardó separadamente bajo `.tools/recovery/senna-mp44-20261017/`.
- Antes de cambiar los archivos de juego se guardaron copias bajo [carpeta backup](.tools/recovery/senna-mp44-20261017/backup/) y el inventario de sus huellas en [SHA256SUMS](.tools/recovery/senna-mp44-20261017/backup/SHA256SUMS). El workspace no es un repositorio Git.
- `senna.7z` corresponde a un contenido real de automóvil y a la estructura del mod; no se asumieron rutas/formatos antes de inspeccionarlo.

## Herramientas y conversión

Se reutilizó el conversor instalado `assetto-corsa-gltf` (código y documentación locales en [assetto-corsa-gltf](.tools/assetto-corsa-gltf/)), adecuado al KN5/texturas DDS encontrados; el conversor emitió GLB con texturas PNG legibles por Godot. Blender se usó para importar e inspeccionar el modelo y organizar las cuatro ruedas conservando transformaciones y materiales; el registro está en [`blender-prepare.log`](.tools/recovery/senna-mp44-20261017/blender-prepare.log), con previsualización [`blender-model-preview.png`](.tools/recovery/senna-mp44-20261017/blender-model-preview.png). La conversión seleccionó el coche `vrc_1988_mclaren_mp4-4_r02_a` y el skin `12_Senna_R02`, con 31 materiales, 56 imágenes, 312 nodos, 110 mallas, 272.877 triángulos y textura principal de 4096×4096. Las cuatro ruedas se construyeron a partir de los cinco objetos asociados a cada conjunto, preservando disco, llanta, frenos, banda y flanco con sus UVs y texturas.

Se conservaron artefactos originales y conversiones para trazabilidad:

- Asset integrado Godot: [`MP44-Senna.glb`](assets/MP44-Senna.glb), 31 MiB.
- Exportación intermedia de juego: [`senna_game.glb`](.tools/recovery/senna-mp44-20261017/convert/senna_game.glb), con inventario de ruedas en [`senna_game.json`](.tools/recovery/senna-mp44-20261017/convert/senna_game.json).
- GLB intermedio de conversión: [`senna_mp44_r02.glb`](.tools/recovery/senna-mp44-20261017/convert/senna_mp44_r02.glb).
- Inventario de skins: [`skins-list.tsv`](.tools/recovery/senna-mp44-20261017/skins-list.tsv).
- Log resumido de extracción/conversión: [`conversion.log`](.tools/recovery/senna-mp44-20261017/convert/conversion.log).

La inspección de Godot informa 315 nodos, 110 mallas y 272.877 triángulos, con dimensiones aproximadas 2,17 × 0,99 × 4,43 m. El modelo conserva cockpit, conductor y espejos integrados; se retiró de la integración un casco cosmético de otro coche para no desvirtuar la identidad Senna. Las texturas originales permanecen enlazadas; la sonda contabilizó 110 superficies inspeccionadas y cero referencias de textura ausentes.

### Física del mod

El vehículo de entrada aporta modelos y jerarquía visual del Assetto Corsa. Sus datos de física de Assetto Corsa no son directamente compatibles con el controlador Godot y **no se convirtieron ni se afirmó haber convertido a Godot**. El juego mantiene su controlador `CharacterBody3D`, caja central y suspensión de cuatro muelles ya existentes. Las distancias de ruedas se derivaron de pivotes medidos del mod: batalla entre ejes Z `2,874 m`, vía delantera `1,816 m`, vía trasera `1,670 m`; centro de rueda delantero Y ≈ `0,313 m`, trasero ≈ `0,327 m`. La caja de colisión conserva el valor del controlador existente.

## Cambios de integración

- [`race.gd`](scripts/race.gd): carga `MP44-Senna.glb` como único vehículo principal, asigna nombre MP4/4 y adapta en ejecución los pivotes medidos a `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr`.
- [`car_controller.gd`](scripts/car_controller.gd): localiza únicamente los cuatro nodos canónicos, identifica los delanteros y los pasa al sistema existente; se retiró la dependencia del nodo de carrocería de la escena antigua. El control, motor, freno, agarre y valores de suspensión existentes no se ajustaron para hacer pasar pruebas.
- [`export_presets.cfg`](export_presets.cfg): incluye el GLB nuevo y deja de requerir los assets Red Bull en el preset Android.
- Las dos cámaras siguen disponibles. La vista de morro se recalibra al pivote delantero Z `-1,505 m` y la altura de neumático medida; la sonda propia de cámara de morro terminó en `passed=true`. La cámara exterior pasó su sonda host y auditoría por píxeles (factor de crecimiento medido 1,91 entre parado/final).
- Se conservaron circuito, trazada moto, cronómetro y controles táctiles existentes; las pruebas lógicas de joystick y cronómetro pasaron.

## Estado de verificación

`verify.sh` se ejecutó con `SKIP_LONG=1 SKIP_HOST=1`, usando `emulator-5558` mientras estaba disponible. Registro de corrida: [`verify.log`](.tools/recovery/senna-mp44-20261017/verify.log); tabla de resultados: [`checks.tsv`](.tools/recovery/integral/checks.tsv). Los IDs y resultados reportados ahí son el resultado íntegro hasta el corte por pérdida del ADB/emulador. La ejecución no se declara satisfactoria.

**Superadas, en host, a partir de la tabla/logs:**

- pista/circuito y rampa del circuito; PBR del circuito (127 mapas, cero errores); runtime, aceleración hasta ~179,7 km/h y frenada a cero;
- lógica de cronómetro/sectores; coordenadas/layout de controles táctiles;
- inventario y análisis de escapatorias; dirección/sentido del mando y respuesta (60 casos); movilidad ante muros e impacto;
- relieve (incluida prueba negativa histórica), reproducción de trazas de velocidad 9880/9879;
- cámara exterior más auditoría de silueta en píxeles; la sonda de morro funcional pasa;
- auditoría de materiales, geometría de entrega y forma de neumáticos del asset; compilación APK, firma, huellas y comprobación de contenido empaquetado (226 recursos).

**Fallidas en el `verify.sh` actual (no ocultadas):**

- `sonda_ruedas`: reutiliza asunciones del coche anterior; recoge dos mallas del volante con nombre que incluye `wheel`, no sólo ruedas. Incluso las medidas de rueda notificaron aire aprox. `+51 mm` en delantera derecha y hundimiento `−58 mm` en trasera izquierda mientras el coche avanza, fuera de los ±30 mm; la prueba reporta 39 errores.
- `sonda_suspension`: 18 errores, incluidos hueco de `99,6 mm` en reposo, suspensión/equilibrio o recorrido fuera del comportamiento esperado en aceleración/frenada, maniobras de curva (prueba pierde trayectoria/velocidad) y una muestra de penetración reportada de `157,4 mm` en el resalto. Es un defecto visible/riesgo por resolver; no debe declararse contacto perfecto.
- `audit_morro`: los criterios de píxeles heredados de la referencia anterior no se cumplen en 200 km/h, curva y frenada: rueda delantera derecha no aparece en máscara y el coche queda descentrado (`x≈0,31`). Aun así, el test geométrico y cambio de vista del morro sí pasó; esta auditoría estricta sigue pendiente.
- `capturar_linea`, `capturar_linea_antes` y `audit_linea`: captura/auditoría heredada de la guía visual no logró detectar el patrón de píxeles suficientemente para evaluar. La línea de trazada no se da por validada visualmente.
- `sonda_agarre`: el coche sale a superficie fuera del asfalto durante 15 muestras de la maniobra; no encontró discrepancias de coeficiente durante esas muestras, pero el criterio de maniobra falló.
- `sonda_subviraje`: 1 fallo; valores máximos observados 1,11 g a 60, 1,43 g a 120, 1,95 g a 180 y 2,63 g a 240 km/h. Al menos una exigencia de capacidad lateral en banco/curva no fue alcanzada.

**No ejecutadas / limitaciones de dispositivo:**

- La vuelta completa de conducción se omitió expresamente con `SKIP_LONG=1`, no se puede considerar pasada.
- Exportar, firmar, empaquetar el GLB nuevo y cargar recursos básicos Android sí pasó. Una compilación preliminar se instaló (`Success`), la actividad arrancó (`Status: ok`, 2,28 s) y se observó el log `[track] Barcelona 2023 Moto layout...`; se guardaron [`android-boot.png`](.tools/recovery/senna-mp44-20261017/android/android-boot.png) (2424×1080) y [`logcat.txt`](.tools/recovery/senna-mp44-20261017/android/logcat.txt).
- La batería integral perdió la conexión del emulador 5558 después del arranque y durante la espera del dispositivo (quedó únicamente 5556 `offline`); por eso su instalación verificada por hash, arranque dedicado, orientation/system bars, gameplay táctil, cambio de cámara mediante toques, FPS y capturas de cámara en el mismo dispositivo no terminaron. El emulador reportó inicialmente Android 17; no es un teléfono físico.
- Sin mediciones de Android sostenidas no se informan FPS, tiempo de GPU ni memoria representativos. La captura de boot sólo acredita que el APK llegó a dibujar en emulador, no una vuelta o controles táctiles funcionales.

## APK producido

- Ruta: [`F1OneShot-BarcelonaMoto.apk`](build/android/F1OneShot-BarcelonaMoto.apk)
- Bytes: `230.238.270` (≈219,5 MiB)
- SHA-256: `8abca7eef1e69a1dcb2d987833a4fa4886c6362b92df9a738c6569aaab7841b0`
- APK de depuración firmado por Godot; `apksigner verify` pasó. `check_packaged.py` encontró 226 recursos, con MP44 en los recursos declarados. APK final recompilado por `verify.sh` el 17-Oct-2026 21:19.
- El APK preliminar se instaló y abrió; no se pudo confirmar su hash en el emulador ni instalar/verificar el APK final después de que ADB desconectara el dispositivo. Por tanto, no se afirma que el binario final exacto haya sido instalado. Este es el APK nuevo del cambio; no se presenta el APK previo como actualizado.

## Recuperación y capturas

Las copias de recuperación de [`race.gd`](.tools/recovery/senna-mp44-20261017/backup/race.gd), [`car_controller.gd`](.tools/recovery/senna-mp44-20261017/backup/car_controller.gd), [`gltf_model.gd`](.tools/recovery/senna-mp44-20261017/backup/gltf_model.gd) y [`export_presets.cfg`](.tools/recovery/senna-mp44-20261017/backup/export_presets.cfg) conservan el estado del proyecto anterior a la intervención, con SHA-256 enumerados en [`SHA256SUMS`](.tools/recovery/senna-mp44-20261017/backup/SHA256SUMS). El asset final se mantiene por separado en [`MP44-Senna.glb`](assets/MP44-Senna.glb); el archivo comprimido de entrada conserva su propia huella arriba.

Capturas PNG reales generadas por las sondas del juego host, no ilustraciones:

- Exterior en Barcelona a 100 km/h: [`100-coche.png`](.tools/recovery/fase-camara/capturas/100-coche.png).
- Morro desde la cámara del juego a 100 km/h: [`morro-100.png`](.tools/recovery/fase-fp/capturas/morro-100.png).
- Coche y ruedas en vista de tres cuartos, reposo: [`reposo-tres_cuartos.png`](.tools/recovery/fase2-ruedas/vistas/reposo-tres_cuartos.png).
- Captura real de ejecución Android/emulador: [`android-boot.png`](.tools/recovery/senna-mp44-20261017/android/android-boot.png).

## Pendientes explícitos

1. Corregir medición/orientación/contacto de cuatro ruedas del MP4/4 sin modificar a ciegas los valores de suspensión ni la física ya establecida; actualizar las sondas que dependen de nombres/jerarquía del antiguo vehículo cuando se justifique.
2. Recalibrar y validar la composición de morro en píxeles y revisar la captura actual contra el resultado visual esperado; reparar la auditoría de la línea visual según el renderizador disponible.
3. Repetir `verify.sh` completo, sin SKIP_LONG, con un emulador estable o dispositivo físico y cerrar las pruebas de toque, cámara, vuelta y rendimiento Android.
4. Revisar la capacidad lateral ante los criterios actuales antes de presentar el coche como validado para conducción.

**Conclusión:** el MP4/4 original está integrado en el proyecto y existe un APK Android fresco, firmado y empaquetado. Una compilación preliminar arrancó en emulador; la versión final identificada por hash no se pudo instalar/verificar porque ADB perdió el dispositivo. La sustitución visual y la cadena de build son reales; las pruebas revelan fallos de geometría/contacto y compatibilidad de medición que impiden certificar el comportamiento completo. No afirmar terminado todo el objetivo hasta resolver los fallos anteriores.
