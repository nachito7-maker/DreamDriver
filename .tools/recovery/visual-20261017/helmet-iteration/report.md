# Ajuste de casco en cámara de morro — 2026-10-17

## Cambio

- Se confirmó que `RedBull-Drive.glb` contiene solo una malla de carrocería y cuatro ruedas; la forma oscura inferior no es un casco separado y el casco 3D de prueba quedaba oculto por la carrocería.
- Se añadió un gráfico SVG de casco inspirado en los colores azul, naranja y rojo de Verstappen, mostrado como detalle de pantalla solo durante la cámara del morro. No se alteraron la cámara, la carrocería, los neumáticos, la suspensión ni los controles.
- Se incluyó el recurso SVG en el preset Android.

## Evidencia

- Captura iterada: `helmet-nose.png`.
- `camera_nose_probe.gd`: 6 escenarios, 2 transiciones, cero errores; `passed=true`.
- `car_wheel_probe.gd`: `passed=true`, cero errores.
- Exportación Android de depuración terminada; SVG importado presente dentro del APK.
- Instalación correcta en `emulator-5554`. La captura del emulador quedó negra y no permitió comprobar el render del juego en Android. `emulator-5556` continúa offline.
- Exportación release no disponible: el preset carece de almacén de claves de lanzamiento; se generó APK firmado de depuración.

## APK

- `build/android/F1OneShot-BarcelonaMoto.apk`
- SHA-256: `5e6404e4272fcd867686661cb6936af19d2dbe6461836d4f28efc12e9b56cbca`
