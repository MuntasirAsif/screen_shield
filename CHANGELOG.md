## 0.1.3

* Docs only: README install version now matches the release. No API or native
  changes.

## 0.1.2

* Docs only: README now reflects 0.1.1 behavior (install version, detection vs
  blocking, iOS `screenshot` event while blocked). No API or native changes.

## 0.1.1

* Fix iOS: `disable()` now sticks — backgrounding or dismissing a native modal
  no longer silently re-applies protection after disabling.
* Android: screen-recording detection is now independent of blocking (it stays
  active while the plugin is attached), matching iOS.
* Example: renamed app id to `com.muntasirashif.screen_shield_example`; add a
  gitignore/CI cleanup and `.github/workflows/ci.yml`.
* Docs: add `AGENTS.md`; set `repository` metadata.

## 0.1.0

* Initial release.
* App-wide screenshot and screen-recording blocking (`enable` / `disable`).
* Manual `suspend` / `resume` for custom native flows.
* Live capture detection stream (`CaptureState.none` / `recording` / `screenshot`).
* Android: `FLAG_SECURE` blocking; recording detection on Android 15+;
  screenshot detection on Android 14+ (while blocking is disabled).
* iOS: secure-field layer blocking; device-wide recording/mirroring detection;
  after-the-fact screenshot detection.
