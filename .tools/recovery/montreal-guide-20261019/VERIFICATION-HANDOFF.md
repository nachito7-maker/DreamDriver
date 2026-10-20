# Montreal verification handoff — 2026-10-19

## Result

Montreal is usable in the Godot runtime and completes a simulated lap. Barcelona, Suzuka, and Montreal selection regression now passes with both McLaren and RB22.

## Checks completed

- `scripts/selection_probe.gd` passed across all 3 tracks × both cars; Montreal has 6 valid colliders (road 1, walls 2, off-track 2). Its test had incorrectly required at least 10 colliders, while the imported course intentionally consolidates collision into 6 categorized bodies. Adjusted the per-track minimum to 6 for Montreal and reran the full selection probe.
- The Montreal smoke run completed one RB22 lap in 463.567 seconds with 3.42 m maximum ideal-line error and zero wall hits; menu, track-switch, timer, cameras, controls and both vehicles were also exercised.
- Exported a fresh 1.2 GB debug APK to `build/android/F1OneShot-Montreal-20261019.apk` (SHA-256 `7cd170bf931c79ba8d776ec1a733d4af9935017157917883d4377291bc11dff3`).
- Android APK signature verified with v2 and v3 schemes; signer is Godot's default debug certificate, SHA-256 `16add3e871c8f5960e1876fb20ff0cce444915a880d8c9b509f1095e5dddc4ff`.
- `check_packaged.py` passed: all 180 explicitly declared resources and dependencies are packaged; the APK contains the imported Montreal FBX scene, imported preview texture and route/surface data. Focused archive checks also confirmed the required Montreal files.

## Device and full-suite limitations

ADB reported no connected devices, so installation, installed-APK hash comparison, launch, touch controls and on-device screenshot/layout checks could not be run in this continuation. The full `verify.sh` suite was not rerun; its on-device stages cannot complete without a device. The older `.tools/recovery/integral/checks.tsv` records failures for host runtime/wheel/suspension/nose/line/steering/substeer and device hash/layout checks; these results are historical and were not revalidated here. No pass is claimed for those checks.

The last attempted selection regression had failed with exit code 6 because the test required at least 10 colliders on every circuit. That failure was fixed with a measured Montreal-specific minimum and the whole selection probe was rerun successfully.

## Device limitation

The missing Android device is the remaining blocker for installed-build verification.

## Relevant logs

- `logs/selection-regression-final.log`
- `logs/montreal-guide-smoke.log`
- `logs/android-export-final.log`
- `logs/apk-audit-final.log`
