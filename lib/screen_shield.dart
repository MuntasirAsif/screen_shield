import 'screen_shield_platform_interface.dart';
import 'src/capture_state.dart';

export 'src/capture_state.dart';

/// Blocks screenshots/recording and reports capture state.
///
/// The native side blocks app content; call [enable] once at startup (or when
/// entering a sensitive screen) and [disable] when done. Blocking does not
/// affect native pickers/share sheets/camera — those are handled internally.
class ScreenShield {
  ScreenShield._();

  static ScreenShieldPlatform get _platform => ScreenShieldPlatform.instance;

  static Stream<CaptureState>? _stateStream;

  /// Emits whenever capture starts/stops, and on individual screenshots where
  /// supported. Backed by a broadcast stream — safe to listen from many places.
  static Stream<CaptureState> get captureState =>
      _stateStream ??= _platform.captureState().asBroadcastStream();

  /// `true` while a recording/mirroring session is active (one-shot read).
  static Future<bool> get isCaptured => _platform.isCaptured();

  /// `true` when blocking is currently applied.
  static Future<bool> get isEnabled => _platform.isEnabled();

  /// Applies screenshot + screen-recording blocking (app-wide).
  static Future<void> enable() => _platform.enable();

  /// Removes blocking.
  static Future<void> disable() => _platform.disable();

  /// Temporarily lifts blocking (e.g. around a custom native flow that is not a
  /// UIViewController presentation). Re-applied by [resume].
  static Future<void> suspend() => _platform.suspend();

  /// Re-applies blocking after [suspend].
  static Future<void> resume() => _platform.resume();
}
