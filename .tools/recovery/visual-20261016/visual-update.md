# F1 visual update — 2026-10-16

## Changes

- Restored a 2400×1080 reference viewport and canvas-item scaling in `project.godot`; the previous viewport-width and scaling settings were part of a commented-out line.
- Enabled 2× 3D MSAA to soften model and cockpit edges.
- Iterated the nose camera to 1.25 m behind the front axle, 0.25 m above wheel height, 4° downward pitch and 61° FOV. This shortens the nose perspective and gives more wheel separation.
- Removed the circular halo and large steering rim that created the center "donut" and black arc. The camera-only cockpit now has a slim crossbar, supports, compact yoke and display, on rendering layer 2.
- Applied anisotropic mip filtering to the car materials for sharper texture detail. Darkened the rubber and muted the rim material to address the pale tire appearance.
- Set the reference viewport to 2400×1080 with canvas-item scaling and enabled 2× 3D MSAA. No vehicle physics or suspension code changed.

## Build and install

- Android debug export completed successfully after the latest camera and material iteration.
- APK: `build/android/F1OneShot-BarcelonaMoto.apk` (236 MB)
- SHA-256: `08bdec0b33bb486b754df5cdfd1fcddccdf6c90b12edc0d3628655ccc250d149`
- Installed successfully on `emulator-5554`; Android reports package version `0.2.0`, updated at 2026-10-16 23:31:40. The emulator has previously remained on the Godot splash screen under SwiftShader, so no post-change gameplay screenshot is available there.
- `camera_nose_probe.gd` passed 6 camera cases and 2 view transitions with 0 geometric errors after increasing the transition arc to 0.95 m; front-chassis vertical clearance measured 0.119 m. Headless screenshot capture is unavailable with the dummy renderer, so this is geometric evidence rather than visual sign-off.

## Iteration 2 — wheel and car definition

- Based on the user's latest Android screenshot (`user-reference-latest.png`), removed the imported livery albedo, metallic, roughness, normal, AO and emission maps from the two wheel surfaces. These inherited maps were still producing pale silver reflections despite the earlier dark tint.
- The tire surface now uses graphite albedo, full roughness and disabled specular; the rim uses dark satin grey with disabled specular. This targets the white glare while retaining separate rim geometry.
- Raised 3D MSAA from 4× to 8× to sharpen wheel and body edges; the 2400×1080 render viewport and anisotropic filtering of the 4K car textures remain enabled.
- Export completed and installation succeeded on `emulator-5554` (package `0.2.0`, updated 2026-10-16 23:45:20). This emulator has previously remained on the Godot splash screen under SwiftShader; no new gameplay capture was available to confirm the rendered result.
- APK SHA-256: `66d5fd4307dd9560737f271ad1929b3f9e3eba96ac010f03419eb0fef87add56`.
- Recovery copies: `iteration-2-source/` (before this iteration) and `iteration-2-final-source/` (after this iteration).

## Iteration 3 — sidewall lettering and wheel framing

- Reviewed the active `RedBull-Drive.glb` and the alternate `VehiclePrototypes/RedBull/production/RedBull.glb`. The active asset has four named, independently posed wheels and dedicated tire/rim surfaces; the alternative is a single mesh with one material and no wheel nodes, so swapping it would lose the controls needed for suspension and wheel finish.
- Added small, shaded `PIRELLI` 3D lettering to both sidewalls of each wheel. The letters are attached to the wheel nodes, so they remain readable at rest and turn with the wheel in motion.
- Moved the nose camera slightly farther behind the front axle and higher above the tire tops to reveal more sidewall and reduce the bottom crop.
- Android export completed and installed on `emulator-5554` (package `0.2.0`, updated 2026-10-16 23:55). As before, the emulator does not provide a gameplay capture under SwiftShader, so the latest visual appearance still needs confirmation on the user's phone.
- APK SHA-256: `4201b82f37cf6768fede6c8e4ea4332d4a15ec7691cddac62898831f47890c1f`.
- Source snapshot: `iteration-3-final-source/`; reference capture: `user-reference-iteration-3.png`.

## Recovery

- Pre-edit source copies: `pre-visual-20261016-225113/`
- User screenshot reference: `user-reference.png`
- Intermediate emulator captures: `iteration-2*.png` and `iteration-final.png` (these show the splash screen, not gameplay).
