# Reparación de los controles táctiles (pedales)

Fecha: 16 de octubre de 2026. Presupuesto: 60 min. **Estado: corrección hecha y medida en el
aparato; la batería completa `./verify.sh` no entró en el presupuesto (ver §5).**

---

## 1. Causa raíz

No era el envío de la entrada ni el controlador: `touch_controls.gd` **registraba** la pulsación
(el pedal se iluminaba) y **la demanda moría en el mapeo del pedal**, por dos motivos:

1. **La demanda se anulaba según la X del dedo.** Con el pedal ya capturado,
   `_update_pedal()` ponía `pressure = 0` si el dedo caía en el margen lateral del recuadro
   (22 px a cada lado), aunque el pedal siguiera «pisado». El margen era ~19 % del ancho del
   pedal: era facilísimo pulsar y no recibir nada.
2. **El recorrido analógico tenía el cero abajo del todo.** La presión se mapeaba sobre el
   recuadro de toque (que empieza 16 px por debajo del pedal dibujado) con `smoothstep`: un
   pulgar apoyado en la mitad baja del pedal pedía **~19 % de gas** y al pie del pedal, ~5 %.
   El coche se movía, pero no respondía.

Además, entre las dos zonas de pedal quedaba una franja muerta (los recuadros no eran
contiguos) y un dedo que **entraba deslizando** en un pedal libre no lo tomaba nunca: había que
clavar el dedo en el panel. Medido en el aparato: pulsar el acelerador al pie del pedal 4 s
dejaba el coche en **0 km/h**; el mismo gesto con el mapeo corregido lo pone a **51 km/h** (§4).

## 2. Archivos modificados

| archivo | cambio |
|---|---|
| `scripts/touch_controls.gd` | el mapeo del pedal (mínimo declarado + sólo altura), la captura por entrada deslizante, las zonas contiguas, y `_publish()` que publica la demanda también en cada evento |
| `scripts/controls_probe.gd` | 33 comprobaciones (antes ~13): zonas contiguas y sin franjas muertas, mínimo al pie del pedal, no se corta al mover el dedo, captura al entrar deslizando, freno+dirección, alternancia gas/freno, extremos de las zonas, nada bloqueado |
| `.tools/recovery/toque_pedales_abaixo.py` (nuevo) | prueba EN EL APARATO con `input swipe` sostenido y velocidad leída del HUD |

## 3. Corrección

* **Mínimo declarado `PEDAL_FLOOR = 0.45`:** una pulsación en cualquier punto del pedal entrega
  al menos el 45 % de la demanda (antes: 5 % al pie, 0 % en el margen). El recorrido sigue siendo
  analógico de 0,45 a 1,00 y se mide contra la curva declarada, como la dirección.
* **La demanda de un pedal capturado depende SÓLO de la altura del dedo:** ya no hay anulación
  por moverse en horizontal (se suelta levantando el dedo o sacándolo de la zona).
* **Zonas contiguas y generosas:** el acelerador se queda toda la esquina inferior derecha y el
  freno la banda hasta la mitad del hueco entre los pedales; ni franjas muertas ni solapes, y la
  zona sube 34 px por encima del panel para el pulgar que llega alto. El botón de cámara está
  arriba a la derecha: ninguna zona lo alcanza.
* **Un dedo que entra deslizando en una zona libre la toma** (ya no hay que acertar el panel).
* **`_publish()` en cada evento:** la demanda llega al coche en el paso de física siguiente, sin
  esperar al fotograma de dibujado.
* **Prioridad explícita:** el freno sigue anulando el acelerador cuando dos dedos pisan los dos
  pedales (ya estaba en `car_controller._read_controls`).

## 4. Pruebas

| prueba | resultado |
|---|---|
| `sonda_controles` (`controls_probe.gd`, canal táctil real, ventana) | **33/33 ok**, 0 fallos |
| `sonda_recto` | ok |
| `sonda_direccion` (regresión de la dirección) | ok (33 PASS) |
| `sonda_mando` (regresión del mando) | ok (60 PASS) |
| `toque_pedales_abaixo` **en el aparato** (APK instalado) | acelerador al pie del pedal **0 → 51 km/h**; acelerador arriba (control) 43 → 203 km/h; acelerador moviendo el dedo al borde lateral 142 → 173 km/h; freno al pie del pedal **45 → 0 km/h** (en la repetición el coche ya estaba parado —2 km/h— por haberse salido tras 173 km/h sin dirección: artefacto del protocolo, no del freno) |

No ejecutadas dentro del presupuesto: `sonda_conduccion` (9 min), `sonda_movilidad` (5 min),
`sonda_subviraje`, y la batería completa. La última batería conocida (fase anterior, código
anterior) quedó en 53 `ok` / 1 `fallo` heredado (`camara_pixeles`).

## 5. `./verify.sh`

**No ejecutada** (la corrida completa tarda ~35-45 min y el presupuesto de 60 min se consumió en
el diagnóstico, la corrección y las pruebas de acelerador, freno y multitáctil, que es lo que el
encargo pedía priorizar). No se relajó ningún umbral ni se tocó ninguna prueba ajena.

## 6-8. APK

| | |
|---|---|
| ruta | `build/android/F1OneShot-BarcelonaMoto.apk` |
| bytes | 247 634 688 |
| SHA-256 | `c75ed1e479c84b2421630c20994fa277e76d9b9919c51d71cc070121c523a4e2` |
| instalado | sí (`install -r --no-incremental`, respuesta `Success`) y ejecutado; la huella del APK instalado **coincide** con la del compilado (mismo SHA-256) |

## 9. Pendientes

1. `./verify.sh` completo y las sondas largas (`sonda_conduccion`, `sonda_movilidad`,
   `sonda_subviraje`).
2. Repetir la prueba del freno en el aparato con el coche ya en marcha y sin salirse de pista
   (el protocolo actual mide el freno al final de la recta, con el coche fuera).
3. `toque` (batería) sigue dependiendo del inyector multitáctil del arnés, que es intermitente;
   la prueba nueva de pedales usa `input swipe` y sólo un dedo, así que el multitáctil real se
   sigue midiendo ahí y en `mando_dispositivo`.
