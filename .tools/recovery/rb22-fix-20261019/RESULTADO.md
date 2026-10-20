# Reparación Red Bull RB22 — 19 octubre 2026

## Cambios

- `scripts/track_data.gd`: el GLB instalado ya tiene aplicada la transformación de AC a Godot. Se eliminó la segunda inversión de los ejes delantero/trasero y lateral en la configuración del RB22.
- `scripts/race.gd`: `wheel_*` era solo la llanta. Se incorporaron los neumáticos `tyre_*` y discos `disc_*`, antes hermanos independientes, a los cuatro pivotes animados. Se preservan sus transformaciones al reunirlos y se calibra la altura de cada conjunto con sus vértices, no con la caja de la llanta. Los neumáticos traseros tienen sufijos rl/rr aunque las llantas usan bl/br.
- `scripts/car_controller.gd`: se prioriza el rayo bajo el buje cuando es válido. Buscar siempre la altura más próxima al fotograma anterior entre todos los rayos de reserva retrasaba el apoyo en pendientes; los offsets se conservan como reserva para juntas de triángulos.
- Sin cambios de potencia, masa, aerodinámica ni coeficiente de agarre; sin modificaciones de assets o de circuitos.

## Validación final

- Parseo Godot `--check-only` de los tres scripts: PASS.
- Selección y montaje de ambos vehículos en los tres circuitos: PASS, salida 0 (`logs/selection-final.log`).
- Geometría, siete fases de giro de las cuatro ruedas, radios a 10/60/120/180 km/h y aceleración: 35 comprobaciones PASS por coche (`logs/final-geometry-*.log`).
- Cadena de joystick táctil en ventana real, dirección visual/física, progresividad, izquierda/derecha, aceleración y frenada: 60 comprobaciones, 0 fallos (`logs/final-touch.log`).
- Conducción de dos tramos por circuito, ambos coches, con sus colisiones activas: seis ejecuciones con salida 0 (`logs/final-{barcelona,suzuka,montreal}-{rb22_2026,mclaren}.log`). Son tramos, no vueltas completas.
- RB22, máximo error absoluto de contacto medido mediante vértices y rayos independientes: Barcelona 11,3 mm, Suzuka 5,1 mm, Montreal 1,5 mm. En plano, por debajo de 1 mm en las siete fases de giro. Apoyo mínimo de tres ruedas en Suzuka y cuatro en los otros tramos. Sin impactos en las maniobras.
- McLaren: máximos 15,6/3,7/17,6 mm respectivamente; todas las pruebas conservadas.
- Recta real, acelerador a fondo durante 5 s: RB22 215 km/h y 151,6 m; McLaren 214 km/h y 151,1 m (`logs/final-comparison.log`).
- Radio con media demanda en plano: 14,06 / 37,14 / 111,86 / 178,85 m a 10/60/120/180 km/h, coincidente con L/tan(delta). A máxima demanda, la adherencia limita el giro: aproximadamente 26 m a 60 km/h, 81 m a 120 km/h y 132 m a 179 km/h. No son especificaciones de fábrica: se conserva el modelo semisimulado compartido.
- Captura nativa de revisión: `rb22-contact.png`, guardada correctamente por Godot.

## Límites y advertencias

- Algunas sondas terminan con un aviso de una instancia ObjectDB sin liberar al cerrar, aunque sus comprobaciones pasan y la salida es 0. No se ha presentado como cierre sin avisos.
- Los AABB rotados de `probe_compare.gd` NO son medidas fiables de penetración: incluyen esquinas vacías. Se utilizan sus datos de aceleración; el contacto se valida con los vértices de las sondas nuevas.
- No se ha generado APK ni probado en dispositivo Android. No se afirma haber reproducido exactamente la física del Red Bull retirado ni datos oficiales del RB22; se ha corregido el montaje, apoyo y coherencia física del coche actual sin inflar el agarre.
- Los hooks de cambios no están disponibles en este host; las comprobaciones se ejecutaron directamente con Godot.
