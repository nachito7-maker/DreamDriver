#!/usr/bin/env bash
#
# Verificación integral del proyecto F1 One Shot, en un solo comando.
#
#   ./verify.sh                  # todo (la vuelta completa tarda ~9 min)
#   SKIP_LONG=1 ./verify.sh       # sin la prueba de vuelta completa
#   SKIP_HOST=1 ./verify.sh       # sin la prueba de GPU del anfitrión
#   SERIAL=emulator-5554 ./verify.sh
#
# Encadena: sondas del juego en el anfitrión (cámara incluida), auditoría del
# circuito y de los materiales entregados, exportación del APK, firma, instalación, huella del APK
# instalado, arranque, registro del dispositivo, orientación y barras del
# sistema, lienzo sin bandas negras, pruebas funcionales de toque (acelerador,
# freno, mando y entradas simultáneas), cronómetro y cámara a varias velocidades
# conduciendo con toques reales.
#
# Sobre el orden: las pruebas de toque van antes del cronómetro porque el
# cronómetro del juego no cuenta hasta que el coche cruza la línea de meta, y el
# coche aparece justo antes de ella. Sobre un coche parado la pantalla no cambia
# y medir ahí sería un falso negativo; las pruebas de toque lo ponen en marcha.
#
# Cada comprobación deja su registro en .tools/recovery/integral/logs/ y su
# resultado en checks.tsv. El informe final es
# .tools/recovery/integral/verificacion-integral.json y el código de salida es
# distinto de cero si falla alguna comprobación obligatoria. Una comprobación
# que no se puede ejecutar se marca "omitida", nunca "ok".

set -uo pipefail
export PATH="$PATH:/opt/homebrew/bin"
# Force every ADB operation through one installed client. Mixing the bundled SDK
# and Homebrew binaries races their server startup on localhost:5037.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

GODOT="${GODOT:-$ROOT/.tools/godot/Godot.app/Contents/MacOS/Godot}"
# Godot, the emulator and this harness must share the same adb server; prefer
# the SDK copy that launched the configured emulator, then fall back to PATH.
SDK="${ANDROID_HOME:-${SDK:-$HOME/Library/Android/sdk}}"
ADB="${ADB:-$SDK/platform-tools/adb}"
[ -x "$ADB" ] || ADB="${ADB:-$(command -v adb)}"
ADB="$(command -v "$ADB")"
SERIAL="${SERIAL:-emulator-5556}"
export ADB
BUILD_TOOLS="${BUILD_TOOLS:-$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)}"
PLATFORM_JAR="${PLATFORM_JAR:-$(ls "$SDK"/platforms/*/android.jar 2>/dev/null | sort -V | tail -1)}"
PKG="com.freebuff.f1oneshot.barcelonamoto"
ACTIVITY="$PKG/com.godot.game.GodotAppLauncher"
APK="build/android/F1OneShot-BarcelonaMoto.apk"
GLB="assets/BarcelonaMoto-Tutorial.glb"
OUT=".tools/recovery/integral"
LOGS="$OUT/logs"
SHOTS="$OUT/shots"

mkdir -p "$OUT" "$LOGS" "$SHOTS"
: > "$OUT/checks.tsv"

SKIP_LONG="${SKIP_LONG:-0}"
SKIP_HOST="${SKIP_HOST:-0}"

note() { printf '\n== %s\n' "$*"; }

# check <id> <obligatoria si|no> <descripción> <comando...>
check() {
    local id="$1" mandatory="$2" desc="$3"; shift 3
    local log="$LOGS/$id.log" start end status
    note "$id — $desc"
    start=$(date +%s)
    if "$@" >"$log" 2>&1; then status=ok; else status=fallo; fi
    end=$(date +%s)
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$status" "$((end - start))" "$mandatory" "$desc" >> "$OUT/checks.tsv"
    tail -n 5 "$log" | sed 's/^/    /'
    if [ "$mandatory" = si ] && [ "$status" = fallo ]; then FALLOS=$((FALLOS + 1)); fi
    [ "$status" = ok ] || true
}

omitir() { printf '%s\tomitida\t0\t%s\t%s\n' "$1" "$2" "$3" >> "$OUT/checks.tsv"; note "$1 — omitida ($3)"; }

# check_reintento <id> <obligatoria si|no> <descripción> <comando...>
# Igual que `check`, pero si el primer intento falla repite el MISMO comando una
# vez. El servidor de adb de este equipo lo comparten el emulador, el IDE y esta
# batería: un corte de un segundo hace fallar una instalación o una captura sin
# que el juego tenga nada que ver. No se relaja ningún criterio: se mide lo
# mismo, y si el segundo intento también falla, la comprobación es un fallo.
check_reintento() {
    local id="$1" mandatory="$2" desc="$3"; shift 3
    local log="$LOGS/$id.log" start end status
    note "$id — $desc"
    start=$(date +%s)
    if "$@" >"$log" 2>&1; then
        status=ok
    else
        echo "    [reintento] el primer intento falló; se repite la misma comprobación"
        sleep 5
        if "$@" >"$log" 2>&1; then status=ok; else status=fallo; fi
    fi
    end=$(date +%s)
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$status" "$((end - start))" "$mandatory" "$desc" >> "$OUT/checks.tsv"
    tail -n 5 "$log" | sed 's/^/    /'
    if [ "$mandatory" = si ] && [ "$status" = fallo ]; then FALLOS=$((FALLOS + 1)); fi
}

probe() {  # probe <id> <script> [--headless]
    local id="$1" script="$2" mode="${3:-}"
    if [ "$mode" = "--headless" ]; then
        check "$id" si "sonda $script" "$GODOT" --headless --path . --script "$script"
    else
        check "$id" si "sonda $script" "$GODOT" --path . --script "$script"
    fi
}

FALLOS=0

# ---------------------------------------------------------------- 1. sondas
note "1. Sondas del juego en el anfitrión"
probe sonda_pista scripts/track_probe.gd --headless
probe sonda_materiales scripts/pbr_probe.gd
probe sonda_runtime scripts/runtime_probe.gd
# Ruedas: mide el modelo MONTADO en la escena (pivote de cada rueda centrado,
# eje de giro lateral, fondo de cada rueda contra el asfalto y residuo respecto
# al plano de los cuatro contactos, y que la rueda gire sin orbitar alrededor de
# su eje). Falla con código distinto de cero si alguna rueda flota, se hunde o
# describe un círculo, que es el defecto que corrigió la fase 2.
probe sonda_ruedas scripts/car_wheel_probe.gd
# Suspensión: las diez pruebas de la fase 4 (parado, aceleración, frenada, dos
# curvas, un resalto de prueba bajo las ruedas izquierdas, compresión y extensión
# de cada rueda, vibración, penetración y geometría de los cuatro neumáticos).
# Falla con código distinto de cero si el recorrido se sale de sus topes, si una
# rueda atraviesa el asfalto o si el cabeceo y el balanceo van al revés.
probe sonda_suspension scripts/suspension_probe.gd
# Cámara de persecución: conduce el coche a 50, 100, 150 y 200 km/h (y parado,
# y una frenada desde 200) y mide en cada caso la separación de la cámara, el
# tamaño del coche EN PANTALLA (proyectando su caja con la cámara real), el
# encuadre, la pista visible por delante, la suavidad de la transición y la
# anticolisión. Falla con código distinto de cero si la distancia no baja al
# acelerar, si el coche no crece en pantalla, si se sale del cuadro o si la
# cámara se mete en el entorno. Necesita ventana: dibuja en un SubViewport de
# 2400x1080 y guarda el fotograma con y sin coche para medir la silueta.
probe sonda_camara scripts/camera_probe.gd
# La silueta se mide OTRA VEZ, ahora en píxeles y sobre los PNG guardados, sin
# usar para nada la geometría: si la caja proyectada estuviera mal, los píxeles
# no la acompañarían.
check audit_camara si "silueta del coche en píxeles sobre las capturas de la sonda" \
    python3 .tools/recovery/camera_pixels.py medida .tools/recovery/fase-camara
# Cámara del MORRO: la segunda vista jugable y su botón. Mide, sobre la cámara
# real del juego y con el lienzo de 2400x1080, la composición en seis situaciones
# (parado, 100, 150, 200 km/h, curva y frenada), que la cámara sea RÍGIDA respecto
# al coche (la distancia dinámica de la persecución no puede moverla), la holgura
# con el perfil real del carenado, y el cambio de vista en marcha en los dos
# sentidos: sin salto, sin atravesar la carrocería, sin parar la carrera y con el
# cronómetro, las vueltas y la distancia de la persecución intactos. Falla con
# código distinto de cero si alguna medida se sale del criterio. Necesita ventana:
# dibuja en un SubViewport de 2400x1080 y guarda los fotogramas.
probe sonda_morro scripts/camera_nose_probe.gd
# La composición se mide OTRA VEZ, ahora en píxeles y sin geometría: la sonda deja
# por caso el coche visible, oculto y sin las ruedas delanteras, más el coche
# pintado de magenta y los neumáticos de cian para recortar las siluetas exactas.
# Se compara contra la REFERENCIA aprobada, medida con una regla declarada.
check audit_morro si "composición del morro en píxeles contra la referencia aprobada" \
    python3 .tools/recovery/fase-fp/morro_pixeles.py
# La línea dinámica de asistencia (rojo frenar, amarillo levantar, verde acelerar), sin
# GPU: velocidad ideal de cada punto contra la capacidad lateral medida, las tres
# envolventes de frenada (la física, la del rojo con la antelación declarada y la cómoda)
# realizables punto a punto, el punto de frenada medido contra (v²−v_curva²)/(2·a) —el rojo
# nunca más tarde que la física y no más pronto que su antelación—, la monotonía con la
# velocidad, la continuidad de los estados en la ventana dibujada, los extremos de la
# pista, el perfil de color que se escribe en la textura (sin escalones) y una vuelta
# COMPLETA conducida sólo con lo que dice la línea, con su control negativo.
probe sonda_linea scripts/driving_line_probe.gd --headless
# Y la misma línea medida EN PÍXELES, con la cámara, la luz y el tonemap del juego: la
# sonda de captura monta la escena de carrera en un lienzo de 2400x1080 y guarda, por caso,
# el MISMO instante con y sin la línea, más la misma pose con la línea forzada a cada uno
# de los tres colores (así el color de referencia es el que pinta el motor ahí). Se ejecuta
# DOS veces: con la corrección de la goma de la trazada y con el material del GLB
# (`-- goma-como-antes`), que es lo que da el antes y el después de la franja azulada.
check capturar_linea si "capturas de la línea y de la goma, después de la corrección" \
    "$GODOT" --path . --script res://.tools/recovery/linea/capturar.gd
check capturar_linea_antes si "las mismas capturas con el material del GLB (el antes)" \
    "$GODOT" --path . --script res://.tools/recovery/linea/capturar.gd -- goma-como-antes
check audit_linea si "la línea y la goma de la trazada medidas en píxeles" \
    python3 .tools/recovery/linea/linea_pixeles.py
# `controls_probe` crea un viewport real; no usar `--headless`, que deja
# _viewport_size en cero y da falsos fallos en todas las coordenadas táctiles.
probe sonda_controles scripts/controls_probe.gd
probe sonda_vuelta scripts/lap_probe.gd
# Auditoría de colisiones: qué cuerpo bloquea al coche al salir del asfalto, si
# el agarre sigue a la superficie pisada y cuánto gira de verdad la dirección.
# `movilidad` necesita ventana porque conduce con el joystick analógico real.
probe sonda_inventario scripts/collision_inventory_probe.gd --headless
probe sonda_escapatorias scripts/offtrack_scan_probe.gd --headless
probe sonda_agarre scripts/surface_grip_probe.gd --headless
# `sonda_sentido` cierra la cadena del mando: mide si un dedo a la derecha gira el
# coche a la derecha. Es la única que comprueba el SENTIDO del giro de extremo a
# extremo, y ya detectó una inversión real en el tope de guiñada.
probe sonda_direccion scripts/steering_probe.gd --headless
# `sonda_direccion` mide el MODELO con la demanda inyectada por el canal del mando
# (`touch_steer`), así que no ve la CURVA del joystick ni el recorrido del dedo. Esta mide
# la cadena ENTERA empujando el anillo del mando con toques de verdad: recorrido del dedo
# -> demanda -> ángulo pedido -> ángulo aplicado -> ángulo de la rueda en pantalla ->
# guiñada y aceleración lateral, a 60/120/180/240 km/h y a 10/25/50/75/100 % del recorrido.
# Es la que detectó la pérdida de giro a media velocidad: con el exponente 1,6 del mando,
# a 120 km/h medio recorrido entregaba 0,43 g (radio 265 m) y a 240 km/h, 0,54 g (815 m);
# hacía falta casi todo el anillo para llegar al agarre. Necesita ventana, como el resto de
# sondas que pisan los controles de toque (sin ventana el lienzo mide 64x64 y ningún toque
# se captura).
probe sonda_mando scripts/steering_response_probe.gd
probe sonda_sentido scripts/steer_sign_probe.gd
# Subviraje: la sonda del encargo de la dirección. Mide la capacidad lateral del coche a
# cuatro velocidades contra la tabla EXIGIDA a un monoplaza con carga aerodinámica, y
# CONDUCE tres curvas reales (lenta, media y rápida, cada una a la velocidad que exige su
# vértice) más los cuatro escenarios de pedal y una transición entre curvas de sentidos
# opuestos, midiendo el desvío HACIA FUERA respecto a la trazada con el mando topado al
# 70 % del recorrido —lo que un dedo sostiene sin llegar al tope—. Falla con código
# distinto de cero si el techo de agarre no llega a la tabla exigida, si el coche se abre
# más de 2 m en una curva, si necesita el tope del mando, si derrapa, si se cruza, si toca
# muro o si asimétrico. Antes de la corrección fallaba en 8 comprobaciones (a 120 km/h
# sostenía 1,10 g donde la tabla pide 1,20; a 180, 1,21 frente a 1,70; a 240, 1,36 frente a
# 2,20; y en la curva rápida a 222 km/h se abría 6,46 m con el mando al 100 %).
probe sonda_subviraje scripts/understeer_probe.gd --headless
probe sonda_movilidad scripts/offtrack_mobility_probe.gd
probe sonda_impacto scripts/barrier_impact_probe.gd
# Relieve invisible de la calzada. La malla de física original de AC trae grupos
# que en AC son RELIEVE del suelo —goma de rueda (MARBLES), badenes (BUMP),
# rejillas (GRILLE), cruces (TRAV), escalones (CNCPTS)— y que en este port, con el
# coche como caja rígida contra una malla trimesh, paraban el coche de golpe:
# medido, 48 caras de MARBLES y 142 de BUMP sobresalían sobre el asfalto sin nada
# dibujado encima. La sonda hace dos medidas independientes: mide cara a cara
# —16 668 caras— cuánto sobresale cada una del suelo que tiene justo debajo; y
# vuelve a montar el circuito tal como viene del GLB, sin pasar por la escena de
# carrera, para comparar cuerpo a cuerpo contra el original. Falla si alguna cara
# de relieve asoma por encima de su suelo, si algún muro o superficie se ha movido
# de donde estaba, o si el relieve no se hundió lo que dice hundirlo.
probe sonda_relieve scripts/relief_probe.gd --headless
# Y lo que cuesta ese hundimiento al arrancar: es un desplazamiento de las formas
# de colisión, no una consulta al espacio por vértice, así que no debe pagar nada.
# No es obligatoria, pero deja el número medido en el informe (la versión que medía
# cara a cara tardaba más de siete minutos y se descartó).
check arranque_relieve no "coste de arranque del hundimiento del relieve" \
    "$GODOT" --headless --path . --script res://scripts/relief_flatten_check.gd
# La maniobra de los vídeos, pero llevada al extremo: acelerador a fondo desde la
# salida y ni un toque de dirección durante 30 s. El coche no se aparta de su rumbo,
# así que cualquier obstáculo no dibujado que siga en la calzada lo para y la sonda
# lo publica con el cuerpo, el punto y la normal que le da el motor de física.
# Falla si el coche se detiene sobre el asfalto (detenerse fuera de la calzada, tras
# salirse por no girar, es conducción y se informa como observación). Necesita
# ventana, como todas las que pisan los controles de toque.
probe sonda_recto scripts/straight_run_probe.gd
# Y la CAUSA, probada en el mismo binario: con `--relieve-como-antes` la sonda
# devuelve el relieve a la altura que tiene en la malla original de AC (+1,50 m) y
# exige lo contrario —que el coche SÍ se clave sobre el asfalto—, que es lo que
# pasaba en los dos vídeos del encargo. No es obligatoria porque su resultado es una
# observación sobre el circuito original, no un requisito del juego entregado, pero
# deja registrado que el bloqueo invisible era este relieve y no otra cosa.
check sonda_recto_causa no "la causa: con el relieve a su altura original el coche SÍ se clava sobre el asfalto" \
    "$GODOT" --path . --script res://scripts/straight_run_probe.gd -- --relieve-como-antes
# Y la prueba que cierra el encargo: la velocidad medida en los dos vídeos se
# reproduce dentro del juego pisando el pedal de verdad y sin tocar la dirección,
# y se exige que el coche no se clave sobre la calzada en ninguna de sus zonas.
# Con ventana, como el resto de sondas que pisan la pantalla: sin ventana el lienzo
# mide cero, los rectángulos de los pedales se colapsan y el toque del freno acaba
# dentro del anillo del mando (medido: el mando salía desviado −0,845 sin que
# nadie lo tocase).
check sonda_replay si "reproducción de la traza de velocidad de los dos vídeos" \
    "$GODOT" --path . --script res://scripts/video_replay_probe.gd -- 9880 9879
if [ "$SKIP_LONG" = "1" ]; then
    omitir sonda_conduccion no "vuelta completa, desactivada con SKIP_LONG=1"
else
    # Con ventana a propósito: sin ventana el lienzo mide cero y los controles
    # de toque no tienen sitio donde colocarse (`_layout_controls` sale antes de
    # calcular los pedales), así que la vuelta no se puede conducir. Con ventana
    # el gestor de ventanas puede retirarle el foco, y entonces el juego suelta
    # los dedos a propósito; la sonda, como haría una persona, vuelve a pisar los
    # controles en el tick siguiente.
    probe sonda_conduccion scripts/driving_probe.gd
fi

# ---------------------------------------------------------- 2. conversión
note "2. Circuito y materiales entregados"
check audit_materiales si "mapas de rugosidad del GLB contra los *_MAP.dds originales" \
    python3 .tools/recovery/audit_track_materials.py
check audit_entrega si "geometría, texturas y coche del GLB entregado" \
    python3 .tools/recovery/audit_delivery.py
# La auditoría de entrega mira la CAJA ENVOLVENTE de cada rueda y la sonda de ruedas
# el modelo MONTADO, pero ninguna de las dos ve la FORMA del neumático. Esta mide
# dentro del GLB la silueta de la banda por sector, los dos diámetros, la corona, las
# normales, las piezas sueltas y el reparto goma/llanta contra el barril. Falla con
# código distinto de cero si una rueda sale ovalada, con muescas o mal montada, que
# es el defecto que corrigió esta fase (y que las otras sondas daban por bueno).
check audit_ruedas_malla si "forma de los cuatro neumáticos dentro del GLB entregado" \
    python3 .tools/recovery/audit_wheels_mesh.py assets/RedBull-Drive.glb

# ------------------------------------------------------------ 3. compilar
note "3. Exportar y firmar el APK"
check compilar si "exportación Android del preset del proyecto" \
    "$GODOT" --headless --path . --export-debug Android "$APK"
check firma si "firma del APK" \
    "$BUILD_TOOLS/apksigner" verify --print-certs "$APK"
check huella_apk si "huellas del APK y de las fuentes" \
    python3 .tools/recovery/check_hashes.py "$APK" "$GLB"
# En el anfitrión `res://` es el árbol de trabajo y cualquier script se carga,
# declare el preset lo que declare; en el teléfono sólo viaja lo que el preset
# empaqueta. Un script nuevo que se quede fuera del `include_filter` no se nota
# en ninguna sonda del anfitrión y deja el juego a medias en el APK, así que se
# revisa el contenido del APK antes de instalarlo.
check empaquetado si "los archivos que el preset declara y sus dependencias viajan en el APK" \
    python3 .tools/recovery/check_packaged.py "$APK"

# ----------------------------------------------------------- 4. instalar
note "4. Instalar en $SERIAL"
# Este servidor de adb lo comparten el emulador, el IDE y esta batería. Cuando
# el servidor se reinicia o el emulador reaparece, el dispositivo se queda un
# instante en "offline" y la orden siguiente falla sin que el juego tenga nada
# que ver. Se espera a que vuelva en vez de dar por fallida una comprobación que
# sólo tropezó con ese hueco; si de verdad no vuelve, la espera termina y la
# comprobación falla igual.
esperar_dispositivo() {
    local intento estado
    for intento in $(seq 1 30); do
        "$ADB" start-server >/dev/null 2>&1
        "$ADB" -s "$SERIAL" wait-for-device >/dev/null 2>&1
        estado=$("$ADB" -s "$SERIAL" get-state 2>/dev/null | tr -d '\r')
        if [ "$estado" = "device" ]; then return 0; fi
        sleep 4
    done
    return 1
}
check_reintento dispositivo si "el emulador responde" esperar_dispositivo
esperar_dispositivo || echo "[dispositivo] no respondió a tiempo; se intenta instalar igual"
check_reintento instalar si "instalación del APK (sin incremental)" \
    bash -c "'$ADB' -s '$SERIAL' install -r --no-incremental '$APK'"
check_huella_instalada() {
    esperar_dispositivo || true
    local ruta local_hash instalada_hash
    ruta=$("$ADB" -s "$SERIAL" shell pm path "$PKG" | tr -d '\r' | sed 's/^package://')
    if [ -z "$ruta" ]; then echo "no se encontró el paquete instalado"; return 1; fi
    rm -f "$OUT/base-instalada.apk"
    if ! "$ADB" -s "$SERIAL" pull "$ruta" "$OUT/base-instalada.apk" >/dev/null; then
        echo "no se pudo extraer el APK instalado"; return 1
    fi
    local_hash=$(shasum -a 256 "$APK" | cut -d' ' -f1)
    instalada_hash=$(shasum -a 256 "$OUT/base-instalada.apk" | cut -d' ' -f1)
    echo "compilado=$local_hash"
    echo "instalado=$instalada_hash"
    [ "$local_hash" = "$instalada_hash" ]
}
check_reintento huella_instalada si "la huella del APK instalado coincide con la del compilado" \
    check_huella_instalada

# ------------------------------------------------------------ 5. arrancar
note "5. Arrancar el juego"
check_arranque() {
    local inicio anunciada=0
    "$ADB" -s "$SERIAL" logcat -c
    "$ADB" -s "$SERIAL" wait-for-device
    "$ADB" -s "$SERIAL" shell am force-stop "$PKG" >/dev/null
    sleep 2
    inicio=$(date +%s)
    "$ADB" -s "$SERIAL" shell am start -W -n "$ACTIVITY" >/dev/null
    for _ in $(seq 1 150); do
        if "$ADB" -s "$SERIAL" logcat -d 2>/dev/null | grep -q '\[track\] Barcelona 2023 Moto'; then
            "$ADB" -s "$SERIAL" logcat -d > "$LOGS/logcat-arranque.txt"
            grep -E '\[track\]|\[pbr\]' "$LOGS/logcat-arranque.txt" || true
            anunciada=1
            break
        fi
        sleep 2
    done
    if [ "$anunciada" = "0" ]; then
        "$ADB" -s "$SERIAL" logcat -d > "$LOGS/logcat-arranque.txt"
        echo "el juego no anunció la pista en 300 s"
        return 1
    fi
    # El anuncio sale antes del primer fotograma dibujado: la primera vez el
    # emulador compila los shaders y la pantalla sigue en la imagen de arranque.
    # Nada de pantalla se mide hasta que el juego dibuja su HUD.
    : > "$LOGS/arranque-espera.log"
    for intento in $(seq 1 90); do
        if env ADB="$ADB" python3 .tools/recovery/screen_check.py ready "$SERIAL" \
                --size "$PANTALLA" >> "$LOGS/arranque-espera.log" 2>&1; then
            echo "[arranque] HUD dibujado tras $(( $(date +%s) - inicio )) s de arrancar"
            return 0
        fi
        sleep 4
    done
    echo "el juego no dibujó su HUD en 360 s (ver $LOGS/arranque-espera.log)"
    return 1
}
# La geometría del aparato se mide UNA vez, antes de mirar la pantalla, y se usa
# para todas las medidas: el juego ancla cada control a un borde y escala con la
# altura, así que dónde cae depende del tamaño real del lienzo. `pantalla`
# comprueba después que el display coincide con lo aquí medido.
PANTALLA=$(python3 .tools/recovery/screen_geometry.py device --serial "$SERIAL" 2>/dev/null | tail -1)
echo "[pantalla] lienzo medido en el dispositivo: ${PANTALLA:-desconocido}"
esperar_dispositivo || true
check_reintento arranque si "el juego arranca y anuncia la variante de motos" check_arranque
check_reintento registro_limpio si "registro del dispositivo sin errores" \
    python3 .tools/recovery/check_logcat.py "$LOGS/logcat-arranque.txt"

# -------------------------------------------------- 6. pantalla y orientación
note "6. Pantalla completa, orientación y HUD"
# El tamaño del lienzo sale del propio aparato, no de una constante: se lee del
# volcado del display y con él se miden las regiones del HUD y de los mandos
# (`screen_geometry.py` reproduce la aritmética del juego: anclajes a los bordes
# y escala por altura). Así la misma batería sirve en un lienzo 2400x1080 y en uno
# 1080x2424 sin relaxar ningún criterio: lo que se exige es horizontal, pantalla
# completa, HUD completo y controles en su borde, no una resolución concreta.
check_reintento pantalla si "horizontal, pantalla completa y barras del sistema ocultas" \
    bash -c "'$ADB' -s '$SERIAL' shell dumpsys window displays > '$LOGS/display.txt'
             '$ADB' -s '$SERIAL' shell dumpsys window windows > '$LOGS/ventanas.txt'
             python3 .tools/recovery/check_display.py '$LOGS/display.txt' '$LOGS/ventanas.txt' \
                 --size '$PANTALLA'"
check_reintento lienzo si "el juego llena la pantalla ${PANTALLA:-conocida} sin bandas negras y con el HUD en su sitio" \
    bash -c "'$ADB' -s '$SERIAL' exec-out screencap -p > '$SHOTS/pantalla.png'
             ADB='$ADB' python3 .tools/recovery/screen_check.py layout '$SHOTS/pantalla.png' \
                 --size '$PANTALLA' --display '$LOGS/display.txt'"

# ------------------------------------------------------------- 7. controles
note "7. Controles de toque en el dispositivo"
preparar_toque() {
    # android.jar en el classpath normal: con -bootclasspath y target 11 javac
    # se niega, y --release resuelve java.* del JDK y android.* del SDK.
    javac --release 11 -classpath "$PLATFORM_JAR" \
        -d .tools/recovery/java .tools/recovery/AndroidTouch.java
    rm -rf .tools/recovery/dex &&    mkdir -p .tools/recovery/dex
    "$BUILD_TOOLS/d8" --output .tools/recovery/dex --lib "$PLATFORM_JAR" \
        .tools/recovery/java/AndroidTouch.class || return 1
    (cd .tools/recovery/dex && jar cf ../android-touch.jar classes.dex) || return 1
    "$ADB" -s "$SERIAL" push .tools/recovery/android-touch.jar /data/local/tmp/android-touch.jar
}
check_toque_jar() {
    javac --release 11 -classpath "$PLATFORM_JAR" \
        -d .tools/recovery/java .tools/recovery/AndroidTouch.java || return 1
    rm -rf .tools/recovery/dex &&    mkdir -p .tools/recovery/dex
    "$BUILD_TOOLS/d8" --output .tools/recovery/dex --lib "$PLATFORM_JAR" \
        .tools/recovery/java/AndroidTouch.class || return 1
    (cd .tools/recovery/dex && jar cf ../android-touch.jar classes.dex) || return 1
    "$ADB" -s "$SERIAL" push .tools/recovery/android-touch.jar /data/local/tmp/android-touch.jar
}
check toque_jar no "herramienta de inyección multitáctil (APK actual)" check_toque_jar

if grep -q '^toque_jar	ok' "$OUT/checks.tsv"; then
    esperar_dispositivo || true
    check_reintento toque si "acelerador, freno, mando y entradas simultáneas, medidos en pantalla" \
        env ADB="$ADB" python3 .tools/recovery/screen_check.py touch "$SERIAL" "$SHOTS/toque" \
            --size "$PANTALLA"
else
    omitir toque si "la herramienta de inyección no se pudo preparar"
fi

# El mando, medido EN EL DISPOSITIVO y no en el anfitrión: la maniobra de dirección del
# inyector (acelerador a fondo y el mando al fondo a cada lado) deja en el registro del
# juego las líneas `[mando]` con la demanda, el ángulo aplicado a las ruedas, el tope de esa
# velocidad, la guiñada y la aceleración lateral. Es la única comprobación que mide el giro
# de extremo a extremo EN EL APARATO con dedos reales: mando -> demanda -> ruedas -> guiñada
# -> g. Falla si la demanda del dedo no llega a las ruedas (el aplicado no es el tope), si
# el coche no gira en el sentido pedido o si a esa velocidad no hay capacidad de giro real.
esperar_dispositivo || true
check_reintento mando_dispositivo si "el joystick táctil real gira el coche en el dispositivo" \
    env ADB="$ADB" python3 .tools/recovery/screen_check.py mando "$SERIAL" "$SHOTS/mando" \
        --size "$PANTALLA"

# ---------------------------------------------------------- 8. cronómetro
note "8. Cronómetro en el dispositivo"
# Después de los toques el coche ya cruzó la línea de meta, así que el
# cronómetro tiene que estar contando. Si aún no lo estuviera, la comprobación
# acelera el coche con toques reales hasta que cruce.
esperar_dispositivo || true
check_reintento cronometro si "el cronómetro avanza en el dispositivo" \
    env ADB="$ADB" python3 .tools/recovery/screen_check.py clock "$SERIAL" "$SHOTS" \
        --size "$PANTALLA"
# Comprobar la superficie otra vez tras todos los toques: la primera captura
# confirma el layout antes del uso, ésta prueba que también sobreviven al toque
# sostenido, al multitáctil y al retorno del joystick.
check_reintento lienzo_final si "HUD y mandos siguen en sus regiones tras la conducción real" \
    bash -c "'$ADB' -s '$SERIAL' exec-out screencap -p > '$SHOTS/pantalla-final.png'
             ADB='$ADB' python3 .tools/recovery/screen_check.py layout '$SHOTS/pantalla-final.png' \
                 --size '$PANTALLA' --display '$LOGS/display.txt'"

# --------------------------------------------- 9. cámara en el dispositivo
note "9. Cámara según la velocidad en el dispositivo"
# El juego se relanza para partir de la salida y se conduce con toques REALES
# sobre los pedales, los mismos que usa la comprobación de toque. La velocidad
# de cada captura se lee de la barra del HUD —no de ningún reloj del
# anfitrión—, así que las capturas se ordenan por lo que el juego pinta; después
# se mide la silueta del coche sobre los PNG y tiene que crecer con la
# velocidad. Es la comprobación de la cámara tal como la vive quien conduce, no
# la de la sonda del anfitrión.
esperar_dispositivo || true
check_reintento camara_dispositivo si "capturas a varias velocidades conduciendo con toques reales" \
    env ADB="$ADB" python3 .tools/recovery/fase-camara/capturar_dispositivo.py \
        "$SERIAL" "$SHOTS/camara" --size "$PANTALLA"
check camara_pixeles si "el coche crece en pantalla al aumentar la velocidad, en el dispositivo" \
    python3 .tools/recovery/camera_pixels.py dispositivo "$SHOTS/camara"
# La línea de asistencia, sobre las MISMAS capturas del dispositivo: que la pintura se vea
# conduciendo con toques reales (medido entre 1.180 y 1.682 píxeles de verde en la banda de
# calzada por delante del coche, de 0 a 261 km/h) y que esa calzada no salga azulada (2-5/255
# de dominante azul mediana; el material de goma del GLB daba 19/255). La banda de medida
# excluye la carrocería azul del coche, que ocupa la parte baja del encuadre y daba 19/255 por
# sí sola: la ventana ancha que se usó primero medía el coche, no el asfalto.
check linea_dispositivo si "la línea y la calzada medidas en los píxeles del dispositivo" \
    python3 .tools/recovery/linea/linea_dispositivo.py "$SHOTS/camara"
# Cambio de vista en el dispositivo: se pisa el botón con un `input tap` real (su
# centro sale de la geometría del lienzo, no de números a mano) y se miden las
# tres capturas —persecución, morro, persecución— con el clasificador de librea.
# En el morro el coche tiene que estar pegado al borde inferior y ser mucho más
# ancho, y el cronómetro tiene que seguir avanzando alrededor del cambio: eso es
# lo que demuestra que la carrera no se detiene ni se reinicia.
esperar_dispositivo || true
check_reintento morro_dispositivo si "el botón cambia de vista con toques reales y la carrera sigue" \
    env ADB="$ADB" python3 .tools/recovery/fase-fp/capturar_morro_dispositivo.py \
        "$SERIAL" "$SHOTS/morro" --size "$PANTALLA"

# ----------------------------------------------------------- 10. rendimiento
if [ "$SKIP_HOST" = "1" ]; then
    omitir fps_anfitrion no "desactivada con SKIP_HOST=1"
else
    check fps_anfitrion no "fotogramas por segundo en la GPU del anfitrión (referencia, no es un teléfono)" \
        "$GODOT" --path . --script scripts/fps_probe.gd
fi

# -------------------------------------------------------------- 11. informe
note "11. Informe"
python3 .tools/recovery/integral_report.py "$OUT"
RESULT=$?

if [ "$RESULT" -ne 0 ]; then
    note "Hay comprobaciones obligatorias que fallan."
else
    note "Verificación completa."
fi
exit "$RESULT"
