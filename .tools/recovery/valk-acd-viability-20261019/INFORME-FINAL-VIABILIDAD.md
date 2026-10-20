# Informe final de viabilidad — físicas del LM Hypercar Valkyrie

**Fecha:** 2026-10-19
**Fase:** auditoría de viabilidad (sin integración)
**Veredicto:** **VIABLE CON LIMITACIONES**

> Este informe decide si se puede construir una configuración propia del Valkyrie en el
> controlador de Godot. **No** declara el coche integrado, **no** valida su física y **no**
> modifica el proyecto. No se generó APK.

---

## 1. Alcance y método

Se revisó el informe previo
[INFORME-ACD-VALK.md](.tools/recovery/valk-acd-viability-20261019/INFORME-ACD-VALK.md),
la extracción temporal `/tmp/valk-acd-inspection-20261019/` (114 miembros, íntegra, mismo
hash que el ACD original), los datos sueltos de `AC2026/valk/` y el controlador de Godot.

**Correcciones respecto al informe previo** (evidencia nueva de esta fase):

1. El nombre `lm_hypercar_valkyrie` **sí** tiene evidencia independiente en texto plano:
   `AC2026/valk/sfx/GUIDs.txt` contiene 21 eventos `event:/cars/lm_hypercar_valkyrie/...`
   y el banco `bank:/lm_hypercar_valkyrie`. No procede de la desencriptación.
2. Los neumáticos **no** son un trasplante íntegro del Toyota TS050. `tyres.ini` conserva
   secciones `__CM_FRONT_ORIGINAL`, `__CM_REAR_ORIGINAL` (backup de Content Manager) y el
   diff demuestra que solo cambiaron **radio, presión estática y curva de desgaste**; los
   coeficientes de agarre son idénticos. La limitación de procedencia se reduce mucho.
3. `coast.lut` es una dependencia **inerte**: `COAST_CURVE=FROM_COAST_REF` selecciona
   `[COAST_REF]` (9600 rpm / 120 Nm) y la sección `[COAST_CURVE]` no se evalúa.
4. El controlador de Godot **no** usa las relaciones de cambio para generar fuerza, ni la
   rigidez de curva declarada, ni un tensor de inercia, ni ARB. Esto se confirma en código,
   no se supone.
5. La aero **no es estática**: `aero.ini` tiene controladores dinámicos que mueven el
   difusor de 20° (parado) a 2° (≥110 km/h) y recortan el ala trasera al 80 % a 260 km/h.
   Los cálculos usan el punto de operación a velocidad, no el `ANGLE` nominal.

## 2. Archivos inspeccionados

**Físicas recuperadas (temporales, solo lectura):** `car.ini`, `engine.ini`,
`drivetrain.ini`, `suspensions.ini`, `tyres.ini`, `brakes.ini`, `aero.ini`,
`electronics.ini`, `colliders.ini`, `ers.ini`, `setup.ini`, `power.lut`,
`kers_torque.lut`, `kers_torque_coast.lut`, LUT de aero (`wing_*_AOA_CL/CD.lut`,
`height_*`), y los `.rto` de relaciones.

**Datos sueltos del vehículo:** `AC2026/valk/ui/ui_car.json`, `extension/ext_config.ini`,
`skins/007/ext_config.ini`, `driver_base_pos.knh`, `sfx/GUIDs.txt`,
`lm_hypercar_valkyrie.kn5` (cabecera y nombres de textura), `collider.kn5` (tamaño).

**Controlador Godot:** [car_controller.gd](scripts/car_controller.gd),
[wheel_suspension.gd](scripts/wheel_suspension.gd), [race.gd](scripts/race.gd),
[track_data.gd](scripts/track_data.gd), `scenes/race.tscn`.

**Referencia comparativa:** `AC2026/rb/data/*` (RB22) para verificar que el formato y las
unidades del Valk se interpretan igual que en un coche ya integrado.

## 3. Fase 2 — evidencia del nombre original

| Evidencia | Tipo | Fuerza |
|---|---|---|
| `sfx/GUIDs.txt`: `event:/cars/lm_hypercar_valkyrie/*` y `bank:/lm_hypercar_valkyrie` | Texto plano en el workspace, generado por el pipeline FMOD del coche | **Alta** |
| `lm_hypercar_valkyrie.kn5` (+ `_lod_b`, `_lod_c`) | Nombre del modelo principal | Alta (nombre de recurso, no de carpeta) |
| `car.ini` descifrado: `SCREEN_NAME=LM Hypercar Valkyrie` | Contenido ya descifrado | Media (circular si se usa para elegir la clave) |
| Copia temporal `lm_hypercar_valkyrie/data.acd` produce INI coherente | Resultado empírico | Alta de funcionalidad, media de identidad |

**Conclusión:** el nombre de coche `lm_hypercar_valkyrie` está corroborado por
`GUIDs.txt`, que es independiente del descifrado y existía antes de esta auditoría. Se
mantiene la cautela: el nombre de **carpeta con el que se empaquetó el ACD** no se puede
demostrar criptográficamente sin el ZIP original (`AC2026/valk.zip` no existe). El riesgo
residual es que la clave derive de una variante (mayúsculas, sufijo) y que el texto
coherente sea una coincidencia de longitud; la validación estructural aplicada (114
nombres simples, `[HEADER]`, INI parseable, 25 muestras de `power.lut`, cierre de
dependencias) hace esa coincidencia muy improbable.

**Consecuencia para la fiabilidad:** los valores recuperados se tratan como
**declarados por el mod**, no como datos certificados del Valkyrie real. La incertidumbre
del nombre afecta a la *procedencia*, no a la coherencia interna de los datos.

## 4. Estado de los datos recuperados

### A. Valores originales recuperados y legibles

- Masa 1100 kg con piloto y sin combustible; inercia declarada 1.700 / 1.050 / 3.750.
- Ralentí 1900 rpm, limitador 8400 rpm, corte 50 Hz, inercia de motor 0.09.
- `power.lut`: 25 muestras de 0 a 11.000 rpm; 429 Nm a 8000, 417 Nm a 8500, 0 a 11.000.
- Transmisión RWD, 7 marchas (2.90 / 2.20 / 1.90 / 1.50 / 1.25 / 1.10 / 1.00),
  final 3.10, diferencial 10 % power / 20 % coast / preload 10, embrague 1200 Nm.
- Batalla 2.922 m, reparto delantero 0.48, vías 1.524 / 1.486, BASEY 0.096 / 0.086.
- Muelles: 80.000 N/m delante, 70.000 detrás; heave 120.000 / 150.000; topes
  150.000 / 140.000; PACKER_RANGE 0.060 / 0.070; amortiguación bump/rebound de dos etapas.
- ARB 130.000 / 35.000 Nm.
- Neumático: radio 0.3395, ancho 0.310, FZ0 4045 N, DY0 1.6945, DX0 1.6945,
  LS_EXPY 0.8895, FRICTION_LIMIT_ANGLE 6.29, PRESSURE_IDEAL 35, compuestos S/M/H.
- Frenos: 5200 Nm, reparto delantero 0.56, ABS ausente, TC presente.
- Aero: cuatro elementos (BODY, FRONT, REAR, DIFFUSER) con LUT de CL/CD y de altura,
  más factores de daño.
- Electrónica/ERS: `ers.ini` con curva de par KERS (máx. 89 Nm a 7000 rpm) y curva de
  recuperación; `MAX_KJ_PER_LAP` sin límite efectivo.

### B. Valores derivados (cálculo propio, no están escritos en el ACD)

| Derivado | Cálculo | Resultado |
|---|---|---|
| Potencia máxima útil | par × régimen en el limitador (8400 rpm, ≈419 Nm) | **369 kW** |
| Potencia en el pico de la LUT | 8500 rpm × 417 Nm (por encima del limitador) | 371 kW (no usable) |
| Potencia eléctrica pico | 89 Nm a 7000 rpm | ≈65 kW (≈11 kW a 8400) |
| CL total (punto de operación ≥110 km/h) | 0 + 0.55 + 0.54 + 0.98×0.90 | **1.972** |
| CD total (mismo punto) | 0.83×0.31 + 0.0167 + 0.085 + 1.04×0.02 | **0.3798** |
| Área por elemento | SPAN × CHORD = 1.6504 × 1.0 | 1.6504 m² |
| CL·S total | 1.972 × 1.6504 | 3.2546 m² |
| Downforce a 100 m/s | 0.5·ρ·v²·CL·S | **19.935 N** |
| Downforce a 250 / 300 km/h | idem | 9.613 N (0.89×peso) / 13.843 N (1.28×peso) |
| Drag a 250 km/h | 0.5·ρ·v²·CD·S | 1.852 N |
| Fuerza de freno | 5200 Nm ÷ 0.3395 m | 15.317 N (≈1.42 g) |
| Fuerza máxima de tracción | 466 Nm × 1ª 2.90 × final 3.10 ÷ 0.3395 | ≈12.340 N |
| Frecuencia de balanceo | √(k/m_corner)/2π | 2.77 Hz delante, 2.49 Hz detrás |
| Altura del CG | (r_del + BASEY_del + r_tras + BASEY_tras)/2 | ≈0.43 m |
| Ángulo de dirección a tope | 180° ÷ STEER_RATIO 13 | 13.85° = 0.242 rad |

### C. Desconocidos o no recuperables

- Nombre de carpeta exacto usado al empaquetar el ACD (solo evidencia indirecta).
- Altura real del CG y tensor de inercia efectivo (solo el declarado y una fórmula AC).
- Área de referencia real y convención de signo/units de las LUT aero.
- Mapa de despliegue híbrido (el modelo Godot no lo soporta).
- Geometría interna de `collider.kn5` (no inspeccionada).
- Fidelidad del mod al Valkyrie real; ninguna prueba dinámica.

## 5. Fase 3 — neumáticos Toyota TS050

`tyres.ini` tiene 480 líneas y tres compuestos (`[COMPOUND_0..2]` S/M/H). La sección
`[FRONT]`/`[REAR]` lleva al final los bloques `__CM_FRONT_ORIGINAL` y
`__CM_REAR_ORIGINAL`, que son el backup automático de Content Manager antes de la última
edición. Comparando `[FRONT]` con `__CM_FRONT_ORIGINAL`:

| Campo | Original | Actual | ¿Cambió? |
|---|---|---|---|
| `RADIUS` | 0.3300 | 0.3395 | Sí |
| `PRESSURE_STATIC` | 32.0 | 35.0 | Sí |
| `WEAR_CURVE` | (curva base) | curva recalculada | Sí |
| `DY0`, `DX0`, `FZ0`, `LS_EXPY`, `ANGULAR_VELOCITY`, `RELAXATION_LENGTH`, FLEX, RIM, TUBE | idénticos | idénticos | No |

**Interpretación.** El mod partió de neumáticos TS050 y le cambió el tamaño y la presión;
no conserva el agarre de otro coche con geometría distinta de forma incoherente: el
`DY0`/`DX0` y la construcción son los mismos para ambos ejes y son plausibles para un
slick de GT/LMP. El radio, ancho y rigidez sí corresponden a la rueda del Valkyrie
(0.3395 m ≈ 26.7", ancho 0.310 m).

**Riesgo real, concreto:** la `WEAR_CURVE` no es la original del TS050 sino una
recalculada, y `LS_EXPY=0.8895` es un valor heredado que en el TS050 estaba calibrado con
un FZ0 distinto. El `FZ0=4045 N` es la carga nominal del TS050, no necesariamente la del
Valkyrie (reparto 48 % delante sobre 1100 kg → ~2.600 N estáticos por rueda, 4.045 N es
más alta que la carga estática real pero razonable como referencia de ensayo).

**Veredicto del apartado:** los neumáticos son **utilizables como base documentada**, con
la reserva de que la curva de desgaste y la sensibilidad a carga provienen de otro coche y
deben validarse por comportamiento (tiempo de vuelta, temperatura, degradación), no
tomarse como dato del Valkyrie. No es un bloqueo.

## 6. Fase 3 — FROM_COAST_REF y coast.lut

`engine.ini` declara:

```
COAST_CURVE=FROM_COAST_REF
[COAST_REF] RPM=9600 TORQUE=120 NON_LINEARITY=0
[COAST_CURVE] FILENAME=coast.lut
```

La clave es que `COAST_CURVE` vale exactamente `FROM_COAST_REF`. Ese token no es un nombre
de archivo: es el selector que le dice al motor que genere la curva de freno motor a partir
de `[COAST_REF]`. `[COAST_CURVE] FILENAME=coast.lut` es una rama **no seleccionada** del
mismo ini; `coast.lut` no se abre. Se confirma además que `coast.lut` no aparece en los
114 miembros del contenedor ni referenciado por otro archivo.

Por tanto:

- `coast.lut` **no es una dependencia ausente**. Es una referencia inerte.
- No hay que inventar ninguna tabla: el freno motor es **120 Nm a 9600 rpm, lineal desde 0**
  (`NON_LINEARITY=0`), aplicable a todo el rango por interpolación lineal.
- `[COAST_DATA]` (COAST0/COAST1/COAST=1.5e-6) es la tercera rama, también inerte.

**Consecuencia:** desaparece la limitación que el informe previo marcaba como crítica. El
freno motor se puede implementar con dos números recuperados.

## 7. Otras dependencias LUT

| Dependencia | Estado | Uso |
|---|---|---|
| `power.lut` | Presente, 25 muestras | Curva de par motor |
| LUT aero (`wing_*_AOA_CL/CD`, `height_*`) | Presentes y legibles | CL/CD por ángulo y altura |
| `kers_torque.lut`, `kers_torque_coast.lut` | Presentes | Par eléctrico y recuperación |
| `coast.lut` | Ausente **e inerte** | Ninguno |
| `tyres.ini` curvas | Inline, no externas | Grip y desgaste |
| `.rto` (relaciones) | Presentes (1st, 2nd, 3rd, final) | Solo para HUD/cambio |

No hay ninguna otra dependencia externa rota. `setup.ini` referencia setups por nombre de
compuesto y de ala; todas las secciones existen.

## 8. Fase 4 — correspondencia real con el controlador

Corrección importante: `car_controller.gd` **no** es un `RigidBody3D` con ruedas
físicas. Es un `CharacterBody3D` que integra fuerzas a mano y aplica guiñada
cinemática (`yaw_rate = v / L · tan(steer)`, limitada por la aceleración lateral
lograda). `wheel_suspension.gd` es un `RefCounted` que resuelve un plano de chasis por
mínimos cuadrados con muelles, no una suspensión por rueda con masa no suspendida.

Esto cambia la tabla y el veredicto:

| Sistema | Original (ACD) | Godot real | Adaptación | Fiabilidad |
|---|---|---|---|---|
| Masa | 1100 kg | `mass_kg` (escalar) | Directa | Alta |
| Inercia / guiñada | 1700/1050/3750 | **No existe**; guiñada cinemática | El yaw se deriva de la geometría; el tensor no se usa. No se puede transferir | No aplica |
| Motor | `power.lut` 25 pts | `engine_peak_power_w` + `max_engine_force_n`; `F = min(Fmax, P/max(v,19))` | Reducir la LUT a Pmax ≈ 369 kW (8400 rpm) y Fmax ≈ 12.340 N; **se pierde la forma de la curva** | Media |
| Freno motor | 120 Nm @ 9600 | Constante `210 N` hardcodeada en `_update_engine_and_forces` | Requiere exportar parámetro o editar código; 120 Nm/r ≈ 353 N a rueda | Media |
| Transmisión | 7 marchas, final 3.10 | `gears` solo para régimen y cambio; la fuerza no usa relación | Las relaciones recuperadas sirven para el HUD; la aceleración no cambia | Baja para física |
| Diferencial | 10/20/preload 10 | No existe | Omitir; declarar tracción trasera simétrica | Baja |
| Suspensión | 80k/70k, topes, ARB 130k/35k | `rate_front_n_per_m` / `rate_rear_n_per_m` (defaults 150k/130k), amortiguador `tau`, recorrido 35/30 mm | Mapear muelles (80k/70k) y ampliar recorrido a ~60/70 mm; **no hay ARB** | Media |
| Neumático long. | DX0 1.6945, FZ0 4045 | Capacidad lateral por carga; el acelerador se limita por círculo de adherencia | Usar `front_grip_fraction` y `tire_load_sensitivity`; DX0/DY0 no entran literalmente | Media |
| Neumático lat. | DY0 1.6945, pico 6.29° | Fuerza lateral única, sin curva ni pico | Ajustar `front_grip_fraction` y capacidad por aero; sin caída por ángulo | Media-baja |
| Frenos | 5200 Nm, reparto 0.56 | `max_brake_force_n` (24.800 N en RB) | 5200/0.3395 ≈ **15.300 N** | Alta |
| Aero | CL 1.972, CD 0.380 | `aero_downforce_n_at_100ms` y `drag_area_m2` (CD·A) | **19.935 N** a 100 m/s y **0.627 m²** | Alta (en el punto de operación) |
| Dirección | ratio 13, tope 180° | `steering_at_low_speed_rad` / `steering_at_high_speed_rad` | 0.242 rad como tope bajo; el tope alto ya lo limita el agarre | Media |
| CG / reparto | `CG_LOCATION=0.48`, altura derivada 0.43 | `front_weight_fraction`, `cg_height_m` | 0.48 y 0.43 m | Media |
| Transferencia carga | Implícita | Momento `m·a·h` repartido por muelles | Funciona con los valores anteriores | Media |
| ERS | 89 Nm @ 7000 | No existe | Omitir y declararlo | Baja |

**Lo que el controlador sí puede representar bien:** masa, potencia pico, tope de fuerza,
frenada, carga aerodinámica y arrastre, reparto de peso, altura de CG, muelles,
amortiguadores, recorrido, radio de rueda y agarre global. Con esos campos el Valkyrie
se conduce con cifras propias y no con las del RB22.

**Lo que no puede representar sin código nuevo:** curva de par (solo pico), relaciones
de cambio en la fuerza, diferencial, ARB, curva de neumático con pico y caída, ERS y
el tensor de inercia. Ninguno de estos es imprescindible para una primera integración
fiable; todos deben declararse como simplificación.

**Trampa concreta detectada:** `wheel_rpm` y la velocidad física usan radio fijo
**0.3783 m** en `car_controller.gd` (líneas 557 y 934), no el radio del coche. Con la
rueda del Valkyrie (0.3395 m) el régimen y las velocidades por marcha saldrían un 11 %
altos. Es un cambio de una línea, pero si se olvida, el HUD miente.

**Otra trampa:** `top_speed_factor = 0.8975` recorta `max_forward_speed_ms` (97 m/s →
313 km/h). Para el Valkyrie hay que fijar el tope con el factor incluido, o el coche se
queda 40 km/h corto sin que nada lo delate.

### 8.1 La aero no es estática: dos controladores la mueven

`aero.ini` no es una foto fija. Además de `ANGLE`, hay cuatro `[DYNAMIC_CONTROLLER_n]`:

| Controlador | Elemento | Combinador | Entrada | LUT | Efecto |
|---|---|---|---|---|---|
| 0 | WING_3 difusor | **ADD** | velocidad | 0→20, 30→20, 60→10, 110→2, 190→2 | AOA del difusor = 20° parado, 2° a partir de 110 km/h |
| 1 | WING_2 trasero | **MULT** | velocidad | 1 hasta 230, 0.8 a 260 | Recorta el CL del ala trasera un 20 % a alta velocidad |
| 2 | WING_4 | ADD | freno | 0→0, 1→20 | Elemento vacío (`empty.lut`), sin efecto útil |
| 3 | WING_5 | ADD | gas | 0→0, 1→20 | Elemento vacío (`empty.lut`), sin efecto útil |

Consecuencia directa: el difusor del Valkyrie es **activo estilo LMP**. Su CL va de 0.30
(AOA 20°, parado) a 0.90 (AOA 2°, ≥110 km/h). Por eso los cálculos de la sección 4 B usan
0.90 y no el 0.80 del `ANGLE=0` nominal: 0.90 es el valor que el coche tiene realmente
cuando la carga aerodinámica importa.

Esto obliga a dos matices en el modelo de Godot:

- A baja velocidad el modelo de CL constante **sobreestima** la carga real: a ≤30 km/h el
total sería 0.55+0.54+0.294 = 1.384 (≈30 % menos que 1.972).
- Por encima de 260 km/h el ala trasera pasa a 0.8: ΣCL ≈ 1.864 (−5,5 %). El tope de
  punta se ve poco afectado, pero conviene no calibrar el drag solo con la cifra de 250.

Ninguno de los dos efectos invalida el uso de una cifra única; ambos se resuelven, si se
quiere más fidelidad, con un `CL(v)` de dos o tres tramos en lugar de una constante.

## 9. Datos que deben estimarse (y cómo)

Ninguno de estos se inventa como si fuera del ACD; se derivan y se documentan:

| Dato | Método | Valor propuesto |
|---|---|---|
| Fuerza máxima de tracción | 466 Nm × 2.90 × 3.10 ÷ 0.3395 | **12.340 N** |
| Potencia pico | par × rpm en el limitador | 369 kW |
| Downforce a 100 m/s | CL · S · 0.5·ρ·v² (CL 1.972) | 19.935 N |
| CD·A | CD · S | 0.627 m² |
| Fuerza de freno | par ÷ radio | 15.300 N |
| Altura de CG | fórmula AC con radios y BASEY | 0.43 m |
| Freno motor a rueda | 120 Nm ÷ 0.3395 | 353 N |
| Ángulo de dirección | tope ÷ STEER_RATIO | 0.242 rad |
| Tope de velocidad | P vs arrastre | ~100 m/s teórico; fijar 97 m/s con factor 1.0 |

Un dato **no** se puede estimar con fundamento: la curva de par completa y el mapa
híbrido. Se usan como pico y como ausencia declarada.

## 10. Riesgos técnicos

1. **Radio fijo 0.3783 m** en régimen y telemetría: HUD y marchas engañosos si no se
   parametriza.
2. **Factor de punta 0.8975**: el coche se queda en ~313 km/h si no se ajusta.
3. **Freno motor hardcodeado** (210 N): con 120 Nm el Valkyrie frenaría distinto y el
   parámetro no es exportado; hay que tocar código (fase posterior).
4. **Sin ARB ni diferencial**: el comportamiento en curva será más neutro de lo real;
   el riesgo es de fidelidad, no de estabilidad.
5. **Recorrido de suspensión 35/30 mm** frente a 60/70 mm del ACD: topes frecuentes en
   frenada y pianos; hay que ampliarlo o el coche saltará.
6. **Aero de una sola cifra**: el CL real depende de altura y AOA, y el difusor es activo
   (20° parado → 2° a ≥110 km/h). Con CL constante el modelo sobreestima la carga a baja
   velocidad (≈30 % en el total a ≤30 km/h) y un 5 % a >260 km/h por el recorte del ala
   trasera. Afecta a la fidelidad, no a la estabilidad.
7. **Procedencia del mod**: los datos son del mod, no del Valkyrie homologado. El
   `power.lut` y las LUT aero no están contrastados con datos públicos.
8. **Nombre de carpeta no demostrado criptográficamente**: si la clave fuera de otra
   variante, los valores podrían ser de otro coche. La coherencia estructural lo hace
   improbable, pero no imposible.

## 11. Pruebas necesarias antes de dar el coche por bueno

En una fase posterior, con el coche ya configurado:

1. **Aceleración 0-100 y 0-200 km/h** medidas y comparadas con la curva de potencia
   declarada (0-100 del orden de 4-5 s con 1,1 t, 12.340 N y el límite de
   acelerador por adherencia del propio controlador).
2. **Punta en recta**: debe coincidir con el tope fijado y no quedar limitada por el
   factor 0.8975.
3. **Frenada 100-0**: distancia coherente con 15.300 N y ~1.4 g.
4. **Curva constante** con `understeer_probe`: capacidad lateral vs downforce; verificar
   que no hay subviraje artificial por `front_grip_fraction`.
5. **Pianos y baches**: comprobar que el recorrido ampliado no topa ni despega el chasis
   (usar `suspension_probe` y `ride_probe`).
6. **Cambio de marchas**: régimen coherente con el radio real (0.3395 m) y relaciones
   recuperadas.
7. **Comparación directa con RB22** en el mismo circuito: el Valkyrie debe ser más lento
   en curva lenta y similar o algo más rápido en recta, nunca idéntico.

## 12. Fase 5 — veredicto

**B. VIABLE CON LIMITACIONES.**

Motivos:

- Hay datos originales suficientes para masa, potencia, frenos, aero, reparto, CG,
  muelles y agarre.
- Las dos dependencias que el informe previo daba por críticas se resuelven: el nombre
  tiene evidencia independiente y `coast.lut` es inerte, no ausente.
- El controlador puede representar los sistemas esenciales con parámetros existentes;
  las carencias (curva de par, diferencial, ARB, ERS, inercia) son simplificaciones
  declaradas, no invenciones, y no impiden una conducción estable y verificable.
- Existe un método de validación con las sondas ya presentes en el proyecto.

No es **VIABLE** pleno porque el controlador no puede reproducir la curva de par, el
diferencial, el ARB ni el ERS, y porque la fidelidad del mod al coche real no está
acreditada. No es **NO VIABLE** porque ninguna de esas carencias bloquea la integración
ni obliga a inventar datos esenciales.

## 13. Condición para continuar

Esta fase **termina aquí**. No se inicia la integración. La fase siguiente solo debería
empezar si se aceptan estas condiciones:

- Parametrizar el radio de rueda (eliminar el 0.3783 fijo) y el factor de punta.
- Exportar el freno motor como parámetro y ampliar el recorrido de suspensión.
- Declarar en el HUD/informe que no hay diferencial, ARB, ERS ni curva de par.
- Ejecutar las siete pruebas de la sección 11 y archivar sus logs.

## 14. Confirmación de solo lectura

- No se modificó ningún archivo del proyecto ni del vehículo.
- No se renombró ni sobrescribió `AC2026/valk/data.acd`; la extracción se hizo sobre una
  copia en `/tmp/valk-acd-inspection-20261019/`.
- No se tocaron los parámetros del Red Bull ni del McLaren.
- No se generó APK.
- El único archivo escrito es este informe, dentro de `.tools/recovery/`.

## Referencias

- Informe previo: [INFORME-ACD-VALK.md](.tools/recovery/valk-acd-viability-20261019/INFORME-ACD-VALK.md)
- Controlador: [car_controller.gd](scripts/car_controller.gd), [wheel_suspension.gd](scripts/wheel_suspension.gd)
- Datos del coche: [ui_car.json](AC2026/valk/ui/ui_car.json), [GUIDs.txt](AC2026/valk/sfx/GUIDs.txt)

