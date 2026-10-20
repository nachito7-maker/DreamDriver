# Informe de viabilidad — físicas del hypercar Valk y acd.py

**Fecha:** 2026-10-19  
**Veredicto:** **VIABLE CON LIMITACIONES** para recuperar referencias de físicas y preparar una integración independiente. No significa que el vehículo esté integrado ni que su física adaptada esté validada.

## 1. Recursos encontrados

En `AC2026/valk/` hay:

- `data.acd` (274.875 bytes; SHA-256 `e53658c1825c08899fdfd88dc455a94043150f359d82f04fdff0c55387ce6e78`).
- `lm_hypercar_valkyrie.kn5` (modelo principal, 105.285.414 bytes), `lm_hypercar_valkyrie_lod_b.kn5`, `lm_hypercar_valkyrie_lod_c.kn5` y `collider.kn5` (2.175 bytes).
- `driver_base_pos.knh`, skins, texturas, sonidos, animaciones y configuraciones de extensión.
- No hay un directorio suelto `AC2026/valk/data/`. Las físicas principales están en el ACD. Fuera de él se encontraron `extension/ext_config.ini` y `skins/007/ext_config.ini`, no el conjunto de físicas.

**`AC2026/valk.zip` no existe** en el workspace. Tampoco se encontró otro ZIP de Valk dentro de `AC2026/`; no se comparó ni se puede afirmar si una copia externa difiere de la carpeta.

## 2. ACD, clave y correspondencia

`acd.py` no estaba instalado en el Python del sistema. Instalé la versión 1.1.0 solo en el virtualenv temporal `/tmp/valk-acd-inspection-20261019/venv`.

**Matiz crítico verificado:** la función `acd.py` deriva la clave de `data.acd` del nombre de su directorio padre. La ruta física disponible es `AC2026/valk/data.acd`, pero leerla literalmente con esa ruta devuelve 114 nombres de miembro plausibles y bytes incorrectos: `car.ini` no contiene texto legible (`[HEADER]` ni `SCREEN_NAME`). Esos 114 nombres y la ausencia de excepción **no son evidencia suficiente de descifrado correcto**.

El nombre de modelo y el `ui_car.json` identifican este coche como `LM Hypercar Valkyrie`. Con esa evidencia, repetí la lectura sin tocar el original usando una copia binaria exacta en un directorio temporal llamado `lm_hypercar_valkyrie/data.acd`. La lectura resultó coherente: `car.ini` contiene `[HEADER]` y `SCREEN_NAME=LM Hypercar Valkyrie`; se pudieron leer valores estructurados y las dependencias LUT. La copia conserva el mismo hash que el original. Por tanto, acd.py **puede** recuperar el contenido si el nombre original del directorio usado para crear el ACD era `lm_hypercar_valkyrie`; el workspace no conserva ese nombre original de forma independiente, así que la identidad/key de la copia no se puede demostrar solo con la estructura actual. Se considera evidencia fuerte, no certeza criptográfica. No se renombró ni movió el original.

## 3. Resultado de extracción y validación

La API `acd.read_file()` con el contexto candidato anterior devolvió 114 miembros. La CLI `acd view` también lista 114 nombres, pero su lectura usando el padre literal `valk` muestra que la CLI no valida que el contenido descifrado sea texto coherente. Tampoco usaría `acd unpack` directamente: no valida traversal de rutas ni evita sobrescrituras.

Para la lectura con la clave candidata, primero validé que los 114 nombres fueran nombres simples (sin rutas anidadas, absolutas, `..` ni separadores); después extraje a:

`/tmp/valk-acd-inspection-20261019/lm_hypercar_valkyrie/extracted/`

Los 114 archivos extraídos coinciden byte por byte con los miembros devueltos por la API. `car.ini` identifica el modelo, la curva `power.lut` se pudo analizar como 25 muestras ordenadas y se inspeccionaron INI/LUT de físicas y referencias. **No** se escribió ni empaquetó ningún ACD.

### Archivos recuperados

Incluye los nueve INI pedidos y la LUT principal:

- `car.ini`, `engine.ini`, `drivetrain.ini`, `suspensions.ini`, `tyres.ini`, `brakes.ini`, `aero.ini`, `electronics.ini`, `colliders.ini`, `power.lut`.
- `ers.ini`, cuatro perfiles `ctrl_ers_*.ini`, `setup.ini`, `fuel_cons.ini`, `damage.ini` y otras configuraciones.
- 71 LUT adicionales: potencia/accesorios, aerodinámica, térmica y desgaste de neumáticos, tracción y perfiles ERS.

## 4. Valores destacados (del contenido coherente descifrado)

Son valores declarados por el mod, no valores recalibrados ni datos certificados del vehículo real:

- **Masa/inercia:** `car.ini`: 1.100 kg con piloto y sin combustible; tensor `1.700, 1.050, 3.750`; tanque inicial 25 l, máximo 62,5 l.
- **Motor:** ralentí 1.900 rpm, limitador 8.400 rpm, inercia 0,09; `power.lut` tiene valores hasta 11.000 rpm y su mayor producto rpm×ordenada ocurre a 8.500 rpm. Si se interpreta la ordenada según la convención habitual de AC como Nm, el pico derivado es ≈371 kW; no es potencia explícita del archivo y depende de esa unidad asumida.
- **Transmisión:** RWD, siete marchas (2,90 / 2,20 / 1,90 / 1,50 / 1,25 / 1,10 / 1,00), final 3,10; también se declaran diferenciales, embrague y tiempos de cambio.
- **Suspensión/geometría:** batalla 2,922 m, CG longitudinal 0,48, vías 1,524/1,486 m. Hay DWB, puntos de wishbone/steering, camber, barras ARB, muelles principales y heave, topes, packers y amortiguación bump/rebound.
- **Neumáticos:** slicks y compuestos soft/medium/hard con radio 0,3395 m, dimensiones, curvas longitudinal/lateral, referencia de carga, flex, presión, camber, desgaste y temperatura. Limitación de procedencia: los bloques declaran `__CM_SOURCE_ID=wec_lmp1_toyota_ts050_2017`, no Valk/Aston Martin; la parametrización está recuperada, pero no se demuestra que sea un neumático específico del Valk.
- **Frenos:** par máximo declarado 5.200 Nm, bias delantero 0,56.
- **Aero:** tablas AOA de ala delantera/trasera, difusor, cuerpo y aleta, más factores de altura; los coeficientes no equivalen por sí solos a newtons sin área de referencia, densidad, convenciones y escalado.
- **Electrónica/híbrido:** ABS `PRESENT=0`; TC presente/activo. `ers.ini` y tablas asociadas incluyen par de entrega/recuperación y perfiles de control. Esto es referencia para modelar, no implementación del KERS.
- **Colisiones:** `colliders.ini` describe un collider de chasis. También existe `collider.kn5`; no se inspeccionó su geometría interna.

## 5. Dependencias, anomalías y coherencia

Las referencias de LUT de aerodinámica, neumáticos, electrónica y ERS examinadas están presentes. `power.lut` también existe.

`engine.ini` contiene `COAST_CURVE=FROM_COAST_REF`, además de una sección alternativa `[COAST_CURVE] FILENAME=coast.lut`. **`coast.lut` no está entre los 114 miembros**. Por el selector principal parece elegirse `COAST_REF`, pero no se asumió cómo Assetto Corsa trata la sección alternativa.

El lector aplicado al padre literal `valk` no proporciona un error confiable de clave incorrecta: devolvió registros sintácticamente parseables, pero texto cifrado. Por eso cualquier automatización posterior debe verificar campos como `[HEADER]`, nombre interno, parseo de INI, valores plausibles y cierre de dependencias, no limitarse a “la llamada no lanzó excepción” o “se creó carpeta”.

## 6. Adaptación a Godot

Se inspeccionaron `scripts/car_controller.gd`, `scripts/wheel_suspension.gd`, `scripts/race.gd`, `scripts/track_data.gd` y `scenes/race.tscn`.

El controlador usa `CharacterBody3D` con dinámica longitudinal/lateral propia, una envolvente simplificada de agarre, downforce cuadrático resumido y suspensión equilibrada sobre cuatro ruedas. Ya hay parámetros configurables/internos para masa, batalla, altura CG, potencia, aerodinámica, drag, distribución de masa, fuerza de motor/freno, RPM, relaciones, dirección, agarre y tasas/recorridos de muelle. `race.gd` instancia el mismo `CarScript` para todos los vehículos del catálogo, que hoy solo contiene McLaren y RB22.

Existe un camino razonable para añadir una **receta/configuración de hypercar independiente**, adaptar solo parámetros compatibles y probarla sin ejecutar las físicas AC y sin copiar las F1. Límites de correspondencia:

- Masa y CG longitudinal son mapeables parcialmente. La altura CG y el tensor completo de inercia no están representados en el modelo actual.
- La tabla de motor puede muestrearse, pero el controlador tiene potencia pico escalar: no conserva curva completa, turbo, KERS ni par de inercias.
- Las relaciones RWD pueden mapearse; la transmisión actual no simula diferencial/embrague/driveline completos.
- El controlador no es Pacejka: no reproduce respuesta transitoria, curva de carga, térmica, desgaste, presión, carcasa y fuerzas individuales por neumático.
- La suspensión Godot usa resortes lineales/límites y transferencia de carga; no implementa cinemática DWB, heave separado, ARB ni amortiguación AC de dos etapas.
- Las LUT aero pueden alimentar una aproximación si se confirman unidades, áreas y signos. No justifican copiar una carga F1 ni inferir downforce absoluto sin cálculo dimensional.
- Frenos y dirección tienen parámetros globales, no freno por rueda ni el steering rack AC completo.

Por lo tanto, **hay vía de adaptación**, pero no es un port literal de INI a variables Godot. La configuración resultante requiere decisiones/hipótesis expresas y validación dinámica; los datos extraídos no garantizan que la física sea correcta.

## 7. Recuperado, derivable y desconocido

- **Recuperado (con la clave candidata):** masa/inercia declaradas, RPM/curva de motor, relaciones/RWD, geometría y parámetros de suspensión, dimensiones/curvas de neumáticos, frenos, tablas aero, electrónica/ERS, collider.ini y LUT asociadas.
- **Derivable bajo hipótesis:** curva de potencia convertida a fuerza/par de rueda, reparto longitudinal inicial desde `CG_LOCATION`, estimaciones aero a partir de CL si se confirman área/unidades, geometría de hubs desde el modelo.
- **Estimaciones/validación necesarias:** que el nombre original para la clave fuese `lm_hypercar_valkyrie`; CG vertical, inercia efectiva Godot, combustible de prueba, interpretación/unidades exactas de tablas, área de referencia, física híbrida y representatividad de los neumáticos Toyota.
- **No disponible/no comprobado:** `AC2026/valk.zip`, archivo `coast.lut`, geometría real de `collider.kn5`, fidelidad al Valkyrie real y toda prueba dinámica de la adaptación.

## 8. Veredicto

**VIABLE CON LIMITACIONES** para recuperar información y preparar una configuración hypercar separada. `data.acd` existe y se obtiene contenido coherente con acd.py al usar el nombre de directorio candidato `lm_hypercar_valkyrie`; la ruta literal `AC2026/valk/data.acd` usa el padre `valk` y produce contenido aparentemente descifrado, pero incorrecto. La falta del ZIP impide compararlo y confirmar externamente el nombre original usado en la clave.

No se afirma que el hypercar ya pueda integrarse con física validada. El paso siguiente, si se autoriza en otra fase, sería corroborar el nombre/key con el paquete original o documentación del mod y luego diseñar y probar una receta Godot propia, prestando atención a la procedencia de neumáticos y a las simplificaciones del controlador.

## 9. Confirmación de solo lectura

No se modificó ningún archivo del proyecto, vehículo ni configuración. El ACD original no se movió ni se renombró y su SHA-256 sigue siendo `e53658c1825c08899fdfd88dc455a94043150f359d82f04fdff0c55387ce6e78`. El virtualenv, copias y extracción temporal están bajo `/tmp/valk-acd-inspection-20261019/`. No se generó ni empaquetó un ACD nuevo; no se creó APK.

### Referencias

- Código Godot leído: `scripts/car_controller.gd`, `scripts/wheel_suspension.gd`, `scripts/race.gd`, `scripts/track_data.gd`.
- acd.py 1.1.0 (virtualenv temporal); upstream: https://github.com/philippkosarev/acd.py
