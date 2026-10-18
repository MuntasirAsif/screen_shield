# screen_shield

Block screenshots and screen recording app-wide, and detect when the screen is
being captured or mirrored, on Android and iOS.

`screen_shield` is a primitive: **block** + **detect**. It does not pause audio or
video itself — that is app policy. Subscribe to the detection stream and decide
what to do.

## Features

- Block screenshots and screen recording for the whole app.
- Detect an active screen recording / mirroring session.
- Detect single screenshots where the OS exposes them.
- Suspend / resume protection around custom native flows.
- No impact on native modals: file/photo/document pickers, share sheets and
  camera keep working while protection is on.

## Platform support

| Capability | iOS 15+ | Android |
| --- | --- | --- |
| Block screenshots | Yes | Yes (`FLAG_SECURE`) |
| Block screen recording | Yes | Yes (`FLAG_SECURE`) |
| Detect recording / mirroring | Yes (device-wide, also when backgrounded) | Android 15+ (API 35) |
| Detect a single screenshot | Yes (`screenshot` event, after the fact) | Android 14+ (API 34), only while blocking is disabled |

## Installation

```yaml
dependencies:
  screen_shield: ^0.1.3
```

## Usage

```dart
import 'package:screen_shield/screen_shield.dart';

// Enable blocking (e.g. in main() or on a sensitive screen).
await ScreenShield.enable();

// React to capture changes.
ScreenShield.captureState.listen((state) {
  switch (state) {
    case CaptureState.recording:
      // A screen recording / mirroring session is active.
      break;
    case CaptureState.screenshot:
      // A single screenshot was taken (where supported).
      break;
    case CaptureState.none:
      break;
  }
});

// One-shot reads.
final bool blocked = await ScreenShield.isEnabled;
final bool capturing = await ScreenShield.isCaptured;

// Temporarily lift protection around a custom native flow, then re-apply.
await ScreenShield.suspend();
await ScreenShield.resume();

// Remove protection entirely.
await ScreenShield.disable();
```

## Behaviour

- **iOS modals are handled automatically.** Presenting a native modal while the
  Flutter layer is re-parented inside the secure field would otherwise leave
  UIKit's layer tree inconsistent and freeze the app after dismissal. The plugin
  intercepts `present` / `dismiss` and suspends protection for the duration of
  any native modal, re-applying it once the modal is dismissed. Flutter-rendered
  dialogs and bottom sheets are not `UIViewController` presentations and are
  unaffected.
- **Android needs no modal handling.** `FLAG_SECURE` applies to the activity's
  window, so other activities (pickers, share sheets, camera) are untouched.
- Protection is re-applied on lifecycle events (Android Activity start; iOS
  `didBecomeActive` / window became key) so it survives backgrounding and
  activity/scene recreation — but only while enabled. After `disable()` it stays
  off; backgrounding or dismissing a native modal will not silently re-enable it.
- **Detection is independent of blocking.** Recording/mirroring detection keeps
  running while the plugin is attached regardless of `enable()` / `disable()`
  (`enable`/`disable` only control blocking). Single screenshots are the exception
  on Android — see Limitations.

## Limitations

- **Simulator / emulator.** iOS blocking is a no-op on the Simulator (the
  protected surface only exists on real hardware). The Android emulator captures
  the host framebuffer and bypasses `FLAG_SECURE`. Verify on real devices.
- **iOS detection is device-wide.** `UIScreen.isCaptured` is `true` whenever the
  screen is captured at all, regardless of which app is on screen.
- **iOS blocking is unofficial.** There is no public API to block screenshots.
  The secure-`UITextField` layer technique is the de-facto approach and can break
  on future OS releases.
- **Android screenshot detection is mutually exclusive with blocking.** The OS
  suppresses `registerScreenCaptureCallback` on secured windows, so the
  `screenshot` event is only emitted while blocking is disabled. On iOS the
  `screenshot` event fires regardless (the captured image is blank while blocked).
- **Android recording detection is Android 15+ only.** Blocking still works on
  all versions.
- **Google Play permissions.** `DETECT_SCREEN_RECORDING` and
  `DETECT_SCREEN_CAPTURE` are restricted permissions; provide a privacy
  justification when publishing.
- **iPad multi-window** is only partially covered.

## Manual test matrix

Run on real devices. For each row, also open the file picker, the share sheet,
the camera and a native alert and confirm the app does **not** freeze and that
protection is restored afterwards.

| Platform | Action | Expected |
| --- | --- | --- |
| iOS | Take a screenshot | Content is blank in the image; `screenshot` event emitted |
| iOS | Start Control-Center screen recording | Content is blank; `recording` event emitted |
| iOS | AirPlay / QuickTime mirroring | `recording` event emitted |
| Android | Take a screenshot | Blocked (no file / blank) |
| Android 15+ | Start the native screen recorder | Content blank; `recording` event emitted |
| Android 14+, blocking off | Take a screenshot | `screenshot` event emitted |

## License

MIT. See [LICENSE](LICENSE).
