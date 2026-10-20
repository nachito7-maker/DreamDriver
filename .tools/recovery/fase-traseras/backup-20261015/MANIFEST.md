# Copia de recuperación — estado de partida de la fase de ruedas TRASERAS

Fecha: 15 de octubre de 2026, 02:05. Máquina: macOS (Apple M1).

Es el estado EXACTO del proyecto antes de tocar nada para reparar la goma de las dos
ruedas traseras del Red Bull. Se copió **antes** de aplicar el parche a
`assets/RedBull-Drive.glb` con `.tools/wheels/reparar_traseras.py`.

## Qué contiene

| Ruta | Qué es |
| --- | --- |
| `assets/RedBull-Drive.glb` | el activo que usa el juego con la goma de las dos traseras partida en ocho piezas (cuatro gajos de 90° y cuatro restos en las juntas) y la llanta vista a través de los huecos |
| `assets/RedBull-Drive.glb.import` | la importación de Godot de ese mismo GLB |
| `assets/RedBull.tscn` | la escena del coche que apunta al GLB |
| `scripts/car_controller.gd` | controlador del coche (no se ha modificado en esta fase) |
| `scripts/wheel_suspension.gd` | suspensión de las ruedas (no se ha modificado en esta fase) |
| `medidas-antes/perfil.txt` | perfil transversal por estación axial de la delantera y de la trasera, por material |
| `medidas-antes/cobertura.txt` | cobertura angular por bin de 5° de las cuatro ruedas, por material |
| `medidas-antes/bordes.txt` | aristas libres (bordes de agujero) por material |
| `SHA256SUMS` | huellas sha256 de lo copiado |

## Huellas del estado de partida

```
a1d3f7ff073bd9bb33ae6f3050b08db3c74a04e1fc0a5e3524b860a9681d0c8a  assets/RedBull-Drive.glb
46cdc3f970e8665250b684a5f9010cd31b8dddc3943a63d0d23374d513299a37  assets/RedBull.tscn
67d7487effa5bda3a8843b57390d5d507df2681b9c683443bd04c70ec2af3efc  scripts/car_controller.gd
381b75ddec8917775292d3aed5b63c2a33e31be8239d9468f42f6ffcd7809a02  scripts/wheel_suspension.gd
```

## Cómo volver a este estado

```bash
cd <raíz del proyecto>
cp .tools/recovery/fase-traseras/backup-20261015/assets/* assets/
shasum -a 256 -c .tools/recovery/fase-traseras/backup-20261015/SHA256SUMS
.tools/godot/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

Los scripts de esta fase (`scripts/*.gd`) no se han tocado, así que la vuelta atrás es
sólo el activo. Para rehacer la reparación desde este estado:

```bash
python3 .tools/wheels/reparar_traseras.py assets/RedBull-Drive.glb /tmp/traseras.glb
cmp /tmp/traseras.glb assets/RedBull-Drive.glb || cp /tmp/traseras.glb assets/RedBull-Drive.glb
```
