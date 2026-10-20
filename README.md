# DreamDriver — F1 One Shot (Godot 4.7.2)

Juego de Fórmula 1 en Godot 4.7.2 con tres circuitos (Barcelona-Catalunya Moto,
Suzuka GP y Montreal Gilles-Villeneuve), tres coches (Red Bull RB22 2026,
McLaren MP4/4 y Aston Martin Valkyrie LMH) y física derivada de los datos de
Assetto Corsa de cada mod.

- Escenas: `scenes/main_menu.tscn`, `scenes/race.tscn`
- Lógica: `scripts/` (`track_data.gd` centraliza circuito, coche y receta física)
- Exportación Android: `export_presets.cfg`
- Verificación integral: `verify.sh` (sondas en el anfitrión, APK, firma y pruebas
  en el dispositivo)

## Estado de la física

La receta de cada coche vive en `scripts/track_data.gd` y se deriva de los INI/LUT
de su `data.acd`:

| Coche | Origen de datos | Informe |
|---|---|---|
| Red Bull RB22 2026 | `AC2026/rb/data` (INI sueltos) | [INFORME-FISICAS-AC.md](.tools/recovery/ac-physics-20261020/INFORME-FISICAS-AC.md) |
| McLaren MP4/4 R02 | `vrc_1988_mclaren_mp4-4_r02/data.acd` | [INFORME-MCLAREN-CURVAS.md](.tools/recovery/mclaren-20261020/INFORME-MCLAREN-CURVAS.md) |
| Valkyrie LMH | `AC2026/valk/data.acd` | [INFORME-FINAL-VIABILIDAD.md](.tools/recovery/valk-acd-viability-20261019/INFORME-FINAL-VIABILIDAD.md) |

El McLaren monta curvas reales de par (`power.lut`), sobrepresión de los dos
turbos, `DY_CURVE` de neumático y el EBD del ala; el controlador (`car_controller.gd`)
las acepta por coche y conserva el modelo agrupado para los que no las declaran.

## Qué se versiona y qué no

El checkout de trabajo pesa 36 GB: 25 GB son herramientas y registros locales
(`.tools/`) y 2.4 GB son medios derivados de mods de Assetto Corsa. GitHub no
admite archivos de más de 100 MB y un repositorio con esos binarios no es
clonable de forma razonable, así que este repositorio contiene:

- todo el código (`scripts/`, `scenes/`), la configuración (`project.godot`,
  `export_presets.cfg`) y el arnés de verificación (`verify.sh`);
- los datos pequeños que el juego lee en ejecución: líneas `fast_lane.ai` /
  `ideal_line.ai` y metadatos `*.surfaces.json` de los tres circuitos
  (`assets/**/*.ai`, `assets/**/*.json`);
- los informes y las sondas de recuperación (`.tools/recovery/**/*.md|py|gd`),
  que documentan de dónde sale cada número.

Fuera del repositorio, por tamaño y por licencia (contenido de terceros):

- mallas y texturas de circuitos y coches (`assets/`, `montreal-guide.fbx`);
- mods comprimidos (`AC2026/*.7z`) y orígenes de pista (`montreal/`);
- prototipos de vehículo (`VehiclePrototypes/`);
- APK firmados (`build/`), caché de importación (`.godot/`) y el resto de
  `.tools/`.

Para ejecutar el proyecto hay que restaurar esos medios en su ruta original
(`assets/…`). Sin ellos Godot abre el código y las sondas de lógica, pero no
puede instanciar circuitos ni coches.

## Ejecutar

```bash
# Godot 4.7.2
godot --path . --editor          # abrir el proyecto
godot --path .                   # menú principal
./verify.sh                      # verificación integral (requiere emulador ADB)
```

## Controles

Táctiles y de teclado: acelerador/freno analógicos, mando de dirección, cambio
automático, cámara de morro y exterior, cronómetro y contrarreloj.
