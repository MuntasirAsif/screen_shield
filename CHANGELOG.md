## 0.1.0

* Initial release.
* App-wide screenshot and screen-recording blocking (`enable` / `disable`).
* Manual `suspend` / `resume` for custom native flows.
* Live capture detection stream (`CaptureState.none` / `recording` / `screenshot`).
* Android: `FLAG_SECURE` blocking; recording detection on Android 15+;
  screenshot detection on Android 14+ (while blocking is disabled).
* iOS: secure-field layer blocking; device-wide recording/mirroring detection;
  after-the-fact screenshot detection.
