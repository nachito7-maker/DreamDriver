# Codex execution report — F1 One Shot Barcelona Moto

Date: 2026-10-16

## Result

A new Android APK was exported, signed, installed on the project AVD (`F1`, `emulator-5558`), started, and hash-checked against the installed `base.apk`. Startup and basic screen/layout checks passed. The full `./verify.sh` run finished with exit code 1: 43/54 checks passed, 11 failed, none omitted. Ten failures were mandatory; one was the optional negative control `sonda_recto_causa` (expected to show the original track-relief defect).

No source code was changed in this execution. The verified wheel-plane fix remains in `scripts/wheel_suspension.gd`. The pre-run integrated logs and APK were copied to `.tools/recovery/pre-codex-20261016-1937/` before verification overwrote the current result folder.

## Suspension, acceleration and full lap

- `sonda_suspension`: PASS, zero errors.
- `sonda_recto`: PASS, reached 313.5 km/h at full throttle and did not stop on the road.
- `sonda_conduccion`: PASS, one lap in 524.20 s, maximum line error 2.21 m, zero wall hits.
- `sonda_movilidad`, `sonda_impacto`, `sonda_relieve`, delivery asset audit and wheel mesh audit: PASS.

## Steering regression comparison

Same fast-curve probe, from saved reports and this run:

| Result | Last good delivery | Current |
|---|---:|---:|
| Peak steering travel required | 69% | 89% (85% limit) |
| Maximum outward deviation | 0.25 m | 1.32 m |
| Maximum lateral drift | 0.28 m/s | 2.55 m/s |
| V70 | 264 km/h | 263 km/h |
| Lateral capacity at 240 km/h | 2.64 g | 2.63 g |

This confirms a residual trajectory/steering-margin regression, while the grip-capacity and V70 checks remain at the previous level. The saved A/B tests rule out ride height (`0.02 m` produced the same 89%) and ride deadband (removing it also produced 89%). Re-enabling floor snap or using measured frame-to-frame acceleration made the curve and suspension substantially less stable, so those are not viable fixes. The evidence does not isolate a safe remaining change; none was made.

## Full verification failures

- `sonda_subviraje`: 89% peak steering travel, over the 85% criterion.
- `sonda_agarre`: the probe spent 15 frames outside the asphalt where it requires 120; all surface/grip samples had zero mismatches.
- `audit_morro`: tire pixels fell below the reference visibility threshold; geometric `sonda_morro` passed.
- `capturar_linea`, `capturar_linea_antes`, `audit_linea`: no sufficiently visible `green_detras` pixel sample; `sonda_linea` passed.
- `toque`: recording captured only 26 frames at 0.37 fps and missed multitouch/release phases. A separate retry with `F1_CAPTURA_TIMEOUT=25` still captured 26 frames at 0.35 fps.
- `mando_dispositivo`: only one left and zero right samples were captured; the left-turn yaw/lateral response was present, but the single frame failed the wheel-pixel direction check.
- `camara_pixeles`: software-rendered device capture reached only 34.8 km/h, so requested 50–200 km/h comparisons were not exercised.
- `morro_dispositivo`: nine failures while the device was at 10.9 km/h; speed and timer did not advance enough during view transitions.

The F1 AVD booted correctly at 2424×1080 but selected Lavapipe/software rendering because the host had insufficient free memory for hardware rendering. The app did launch cleanly, and the assist line was visible in 30/30 device captures; its road tint audit passed.

## APK

- Path: `build/android/F1OneShot-BarcelonaMoto.apk`
- Size: 247,638,784 bytes
- SHA-256: `3b061e1a6f795ee8c91b061e44274f2ebae6720f41c0ababf0d89883f96297e0`
- Installed APK SHA-256: identical, verified by `huella_instalada`.

## Evidence

- Full results: `.tools/recovery/integral/checks.tsv`
- Full JSON: `.tools/recovery/integral/verificacion-integral.json`
- Understeer: `.tools/recovery/integral/logs/sonda_subviraje.log`
- Suspension: `.tools/recovery/integral/logs/sonda_suspension.log`
- Acceleration: `.tools/recovery/integral/logs/sonda_recto.log`
- Full lap: `.tools/recovery/integral/logs/sonda_conduccion.log`
- Device touch retry: `.tools/recovery/integral-device/f1-timeout-touch/touch.json`
- Preserved pre-run artifacts: `.tools/recovery/pre-codex-20261016-1937/`
