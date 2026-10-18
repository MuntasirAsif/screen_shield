# AGENTS.md

## What this is
Flutter plugin `screen_shield` (Android + iOS): blocks screenshots/screen
recording and detects capture state. CI (`.github/workflows/ci.yml`) runs Dart
analyze/test plus Android and iOS builds.

## Commands
- Deps: `flutter pub get` (also resolves `example/` via a path dependency).
- Lint: `flutter analyze` — covers Dart only; `analysis_options.yaml` excludes
  `android/`, `ios/`, so native errors surface only via builds/gradle tests.
- Unit tests: `flutter test`
  - one file: `flutter test test/screen_shield_method_channel_test.dart`
  - one case: `flutter test --plain-name 'captureState parses event-channel strings'`
- Example: `cd example && flutter pub get && flutter analyze && flutter test`
- Android native unit test: `cd example/android && ./gradlew :screen_shield:testDebugUnitTest`
- Android build: `cd example && flutter build apk --debug`
- iOS build (macOS/Xcode only): `cd example && flutter build ios --debug --no-codesign`
- Publish: `dart pub publish --dry-run`, then `dart pub publish` (warns unless the
  git tree is clean and no gitignored files are checked in — commit first).

## Architecture / wiring
- Channels are the whole contract; keep them identical across all three layers:
  - `screen_shield/method` — enable/disable/suspend/resume/isEnabled/isCaptured
  - `screen_shield/event` — emits `none` | `recording` | `screenshot`
  - Dart: `lib/screen_shield_method_channel.dart`
  - Android: `android/src/main/kotlin/com/muntasirashif/screen_shield/ScreenShieldPlugin.kt`
  - iOS: `ios/screen_shield/Sources/screen_shield/{ScreenShieldPlugin,ScreenShieldCaptureDetector}.swift`
- Dart deliberately keeps the `plugin_platform_interface` split: `ScreenShield`
  static facade -> `ScreenShieldPlatform.instance` (`MethodChannelScreenShield`).
  Don't collapse it into a single class.
- Android package `com.muntasirashif.screen_shield` must match the Kotlin dir AND
  `pubspec.yaml` `plugin.platforms.android.package`.
- iOS uses Swift Package Manager layout: sources live in
  `ios/screen_shield/Sources/screen_shield/` (NOT `ios/Classes/`); both
  `Package.swift` and `screen_shield.podspec` list them.
- `ScreenShieldProtector` re-parents the Flutter layer into a secure
  `UITextField` and swizzles `UIViewController.present/dismiss`
  (`ss_present`/`ss_dismiss`) to suspend protection during native modals. This is
  what prevents the "app frozen after a file/picker modal" bug — never mutate the
  layer tree while a modal is presented.

## Gotchas (verified, non-obvious)
- Android `ActivityPluginBinding.getLifecycle()` returns `Object`; cast it to
  `androidx.lifecycle.Lifecycle` before `addObserver` (needs the
  `androidx.lifecycle:lifecycle-common` dependency).
- iOS plugin `handle(_:result:)` must be declared `public` (FlutterPlugin requirement).
- Android recording detection is API 35+ (`VANILLA_ICE_CREAM`); screenshot
  detection is API 34+ (`UPSIDE_DOWN_CAKE`) and is only registered while blocking
  is OFF, because FLAG_SECURE suppresses it. Keep the runtime SDK_INT guards.
- Detection is deliberately independent of blocking on both platforms: recording
  detection is tied to the Android Activity lifecycle (attach/start/stop) and
  registered once at plugin init on iOS; it is NOT toggled by `enable`/`disable`.
  Don't re-couple them.
- iOS blocking is a no-op on the Simulator; the Android emulator bypasses
  FLAG_SECURE. Block/detect can realistically be verified only on real devices.
- Example uses file_picker v13 static API: `FilePicker.pickFiles()` (no `.platform`).

## Repo conventions
- Renames ripple across `pubspec.yaml` plugin block, the Kotlin package dir, iOS
  source path + `screen_shield.podspec`/`Package.swift`, and example imports.
- Release: bump `version:` in pubspec + add a `CHANGELOG.md` entry. pub.dev
  metadata is immutable per published version, so metadata fixes require a new version.
- The example app uses id `com.muntasirashif.screen_shield_example`; the iOS
  example's bundle id is still the scaffold default (not renamed).
