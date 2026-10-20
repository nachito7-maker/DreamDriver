# Revisión visual F1 — 2026-10-17

## Hallazgo

El vídeo `MicrosoftTeams-video (1).mp4` muestra el encuadre del morro retrasado y las ruedas con goma clara y aspecto de banda separada. El origen del retroceso era que `_configure_car_texture_filtering()` se llamaba antes de que el wrapper GLB añadiera las mallas importadas en `_ready()`. El recorrido de materiales estaba vacío, así que no se aplicaban ni los materiales de rueda ni el filtrado anisotrópico de la carrocería.

## Cambios aplicados

- Se ejecuta la configuración de materiales después de incorporar el coche al árbol de escena.
- Se recupera el encuadre aprobado: 1,25 m detrás del eje delantero y 0,25 m sobre la altura de rueda; se mantienen 4° y FOV 61°.
- La goma usa albedo casi negro, rugosidad máxima y sin especular; la llanta queda en grafito mate.
- Se mantiene una sola malla/transforms por rueda para neumático y llanta, y se quitan las letras 3D que se habían superpuesto.
- El filtrado anisotrópico de los mapas de 4K de carrocería ahora sí se aplica en ejecución.
- No se modificaron controles, dirección, física, suspensión ni el botón de pausa.

## Verificación posterior a la corrección

- `camera_nose_probe.gd`: 6 casos, 2 transiciones, cero errores; comparación de composición aprobada.
- `car_wheel_probe.gd`: cuatro ruedas; pivotes centrados, eje lateral, órbita 0, giro con transformación común; `passed=true`, cero errores.
- Inspección del árbol en ejecución: los cuatro neumáticos muestran albedo `(0.010, 0.011, 0.013)`, rugosidad 1, sin textura ni especular. Capturas en `../../fase-fp/capturas/` y vistas detalladas en `../../fase2-ruedas/vistas/`.
- `verify.sh` (antes del último arreglo de orden de carga) recorrió las sondas generales. Pasaron cámara, morro, ruedas, suspensión, controles, dirección, movilidad, impactos, relieve, replay y una vuelta completa (524,22 s; desviación máx. 2,21 m; cero muros). Marcó fallos en auditoría/captura de línea, una maniobra de agarre fuera de pista y una comprobación del banco de subviraje; `sonda_recto_causa` también falla como comprobación informativa.
- La batería se detuvo al esperar `emulator-5556`, que estaba `offline`. El APK actualizado se instaló aparte en `emulator-5554`; la extracción `base-installed-5554.apk` coincide byte a byte con el APK de entrega.
- El emulador Android inicia Godot GLES con SwiftShader, pero la captura queda en la pantalla inicial y no permite observar la carrera. No se da por superada la validación visual en dispositivo.

## Entrega

- APK: `build/android/F1OneShot-BarcelonaMoto.apk`
- SHA-256: `77b8745a560dcae3ae205f0077cb54ae11a72da85df7b1b7d44847b5a14d775d`
- Copia extraída del emulador: `base-installed-5554.apk` (hash idéntico)
- Copia fuente anterior al arreglo: `source-before/race.gd`
