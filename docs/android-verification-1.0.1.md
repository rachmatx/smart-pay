# Android verification — Smart Pay 1.0.1

11 November 2026. Branch `feat/manual-server-settings`.

- Dart analyzer: no issues.
- Flutter unit/widget tests: 16 passed.
- Real loopback Node/SQLite Payment API: 1 scenario passed (health/key, create, UUID lookup, simulated payment, history and stale server guard); callback disabled, disposable database, no actual money.
- UI capture: 1 scenario passed; Roboto/Material Icons loaded, fictional merchant, screenshot reviewed. Form and navigation tested at 320 px with text scale 1.8 and keyboard insets.
- Flutter 3.47.9 / Dart 3.13.7 / JDK 21 / Gradle 9.1.0 / Android SDK 36.
- Ran `flutter pub get --offline` to generate native plugin registration before building. Dart pub alone is insufficient on a fresh checkout.
- Build: `flutter build apk --release --target-platform android-arm64 --split-per-abi --build-name=1.0.1 --build-number=2`.
- Package `com.smartpay.smart_pay`, version name 1.0.1; ABI-derived Android version code 2002. Minimum SDK 24, target SDK 36.
- ARM64-only native libraries; camera permission and native registrant classes for secure storage, scanner, local_auth and JNI confirmed.
- `apksigner verify --verbose`: valid v2 signature, internal debug signing. `zipalign -c -P 16 4`: passed.
- APK bytes: 29240363. SHA-256: `64be91c97a4f93160fe4a899ce53bab498d195db0c4381f290585165c2366147`.

The initial build without generated native registration was discarded. An intermediate universal container carrying foreign scanner ABIs was replaced by the ARM64 split output. Only the checked final artifact is distributed.

No physical phone attached. Camera, biometrics, secure storage after Android process death and actual LAN connectivity remain manual-device checks. If upgrading an APK signed by another debug key fails, reinstall the test app after preserving any necessary local settings; backend transactions remain on the server. Server switching does not cancel requests already sent to an old backend.
