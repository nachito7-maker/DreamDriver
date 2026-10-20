# Wheel motion review — 2026-10-17

- Reviewed `MicrosoftTeams-video.mp4` (8.19 s, 1280×720), sampling frames every 0.5 s and comparing close crops of both front wheels.
- The active `RedBull-Drive.glb` has four named wheel nodes, with tire and rim as two material surfaces on the same wheel mesh. The controller rotates that mesh around its centered X axle, so the rubber and rim do not have independent transforms.
- The visible separation came from the floating sidewall lettering: its plane was tilted 45° relative to the wheel face. The 3D marks are now flush with the sidewall plane and remain attached to the rotating wheel. The camera was moved 0.25 m farther behind the axle and lowered to reveal more wheel.
- Exported APK: `build/android/F1OneShot-BarcelonaMoto.apk`
- SHA-256: `37d3a63096b5fb0c8a507055573625724099deaa91a1d9e3aabf0c7ea7af2a41`
- Installed successfully on `emulator-5554`. The emulator still cannot provide a gameplay view under SwiftShader, so the latest visual result awaits confirmation on the user's Android device.
- Source before change: `wheel-sync-source/`; updated source: `wheel-sync-final-source/`.
- Video and extracted frame crops are preserved in this directory.
