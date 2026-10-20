# Copia de recuperación — estado de partida de la fase 2 (ruedas)

Fecha: 14 de octubre de 2026, 13:37. Máquina: macOS (Apple M1).

Es el estado EXACTO del proyecto antes de tocar nada para corregir las ruedas del
Red Bull. Se copió antes de la primera intervención sobre `scripts/car_controller.gd`
y antes de reconstruir `assets/RedBull-Drive.glb`.

## Qué contiene

| Ruta | Qué es |
| --- | --- |
| `scripts/car_controller.gd` | controlador del coche con la pose del modelo invertida (`pitch + _body_pitch`, `atan2(-local_normal.z, …)`) y el vuelco aplicado al coche entero |
| `scripts/race.gd` | escena de carrera y controlador de cámara de persecución |
| `scripts/track_data.gd` | circuito: centrolinea, superficies y agarre |
| `scripts/gltf_model.gd` | carga del modelo glTF del coche |
| `assets/RedBull-Drive.glb` | modelo del coche con las ruedas descentradas y giradas (pivote a 6,6–11,7 mm del centro de la malla y rotación horneada de 90° + 180°) |
| `assets/RedBull-Drive.glb.import` | importación de Godot de ese mismo GLB |
| `assets/RedBull.tscn` | escena del coche que apunta al GLB |
| `medidas-antes/` | las medidas que documentan el defecto (§2 del informe): sondeo en ejecución, geometría de las ruedas, perfil y mapa del chasis |
| `logs/apk-hashes-steering.txt` | huella del APK del cierre anterior (fase 1) |

`SHA256SUMS` recoge la huella de todos los archivos de esta copia.

## Cómo volver a este estado

```bash
cd <raíz del proyecto>
cp .tools/recovery/fase2-ruedas/backup-20261014/scripts/*.gd scripts/
cp .tools/recovery/fase2-ruedas/backup-20261014/assets/* assets/
shasum -a 256 -c .tools/recovery/fase2-ruedas/backup-20261014/SHA256SUMS
```

No hace falta nada más: la corrección de las ruedas de la fase 2 vive entera en
`scripts/car_controller.gd`, `assets/RedBull-Drive.glb` y las sondas nuevas
(`scripts/car_wheel_probe.gd`, `scripts/car_delivery_probe.gd`), que no existen en
esta copia.
