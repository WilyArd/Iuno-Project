# AGENTS.md – Repo‑specific guidance

**Setup & toolchain**
- Install Flutter SDK (≥ 3.11) before any other step.
- After cloning, run `flutter pub get` to fetch Dart/Flutter dependencies.

**Running the app**
- `flutter run` – launches on the first connected Android device or emulator.
- The entry point is `lib/main.dart` → `MainApp` → `SplashView`.
- The UI uses **GetX** (`GetMaterialApp`) for routing and state management.

**MQTT integration (runtime requirements)**
- The broker address is hard‑coded in `DashboardController._initMqtt` as `192.168.10.3`.
- Client IDs are generated at runtime; no external config needed.
- Topics used:
  - Subscribe pattern `iuno/+/discovery/#` for device discovery.
  - Publish `iuno/device/cmd` with payload `rediscover` (sent 2 s after connect).
  - Device‑specific state and command topics are derived from the discovery payload (fields `stateTopic` and `commandTopic`).
- The `MqttService` maintains a **single global listener**; do **not** add extra `client.updates.listen` calls.
- Disconnect logic is encapsulated in `DashboardController.toggleConnection` and `onClose`.

**Testing**
- No dedicated test suite is present; the default `flutter test` command will run any future tests.
- Lint/analysis can be invoked with `flutter analyze` (uses `flutter_lints`).

**Project structure shortcuts**
- UI pages live under `lib/features/*/views/`.
- Controllers (GetX) reside in `lib/features/*/controllers/`.
- Core services (e.g., MQTT) are under `lib/core/services/`.
- Assets folder declared in `pubspec.yaml` – place static files under `assets/`.

**Common pitfalls**
- Forgetting to run `flutter pub get` after a fresh clone prevents compilation.
- Running on a device without network access will cause MQTT connection timeouts; ensure the device can reach `192.168.10.3`.
- The app expects Android API 21+; older emulators will refuse to launch.
