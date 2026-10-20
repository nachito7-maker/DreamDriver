# Volver al estado previo a la fase 3

## Reversión exacta del entregable

El APK de la fase 2 está guardado aquí sin tocar:

```sh
cp .tools/recovery/fase3-suspension/estado-previo/F1OneShot-BarcelonaMoto.apk build/android/
adb -s emulator-5556 install -r build/android/F1OneShot-BarcelonaMoto.apk
```

SHA-256: `01b2ec6a4496401e89a16bc06741bf0c2d56b86bd9604bfa84c7ab84200b599f`

## Reversión del código

La fase 3 AÑADE dos archivos y MODIFICA dos:

* nuevos: scripts/wheel_suspension.gd, scripts/suspension_probe.gd
* modificados: scripts/car_controller.gd, scripts/car_wheel_probe.gd

Para volver al código de la fase 2:

```sh
rm -f scripts/wheel_suspension.gd scripts/suspension_probe.gd
```

y deshacer los cambios del controlador, que están todos en funciones
concretas y documentados en `.tools/recovery/fase3-suspension/INFORME-FASE3-SUSPENSION.md`
(sección «Archivos modificados»): la suspensión por rueda entra en
`_configure_suspension`, `_sample_wheel_contacts` y `_update_visuals`, y el
balanceo y cabeceo prefijados de la fase 2 salían de
`_update_engine_and_forces` (`_body_roll`, `_body_pitch`).

## Estado de la fase 3

En `estado-fase3/` queda copia de los cuatro archivos tal y como están al
cerrar la fase, con sus huellas en `SHA256SUMS`.
