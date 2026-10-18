/// What the OS currently reports about screen capture on this device.
enum CaptureState {
  /// Nothing is capturing the screen.
  none,

  /// A screen recording or mirroring session (AirPlay/QuickTime) is active.
  recording,

  /// A single screenshot was taken (emitted only where the OS exposes it).
  screenshot;

  /// Parses the string sent over the event channel. Unknown values map to
  /// [CaptureState.none] so the wire format can grow without breaking clients.
  static CaptureState fromWire(Object? raw) {
    switch (raw) {
      case 'recording':
        return CaptureState.recording;
      case 'screenshot':
        return CaptureState.screenshot;
      default:
        return CaptureState.none;
    }
  }
}
