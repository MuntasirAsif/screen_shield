import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'screen_shield_method_channel.dart';
import 'src/capture_state.dart';

/// The interface that platform implementations of `screen_shield` must
/// implement.
abstract class ScreenShieldPlatform extends PlatformInterface {
  /// Constructs a [ScreenShieldPlatform].
  ScreenShieldPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScreenShieldPlatform _instance = MethodChannelScreenShield();

  /// The default instance of [ScreenShieldPlatform] to use.
  ///
  /// Defaults to [MethodChannelScreenShield].
  static ScreenShieldPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScreenShieldPlatform] when
  /// they register themselves.
  static set instance(ScreenShieldPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Applies screenshot + screen-recording blocking (app-wide).
  Future<void> enable() {
    throw UnimplementedError('enable() has not been implemented.');
  }

  /// Removes blocking.
  Future<void> disable() {
    throw UnimplementedError('disable() has not been implemented.');
  }

  /// Temporarily lifts blocking. Re-applied by [resume].
  Future<void> suspend() {
    throw UnimplementedError('suspend() has not been implemented.');
  }

  /// Re-applies blocking after [suspend].
  Future<void> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  /// `true` when blocking is currently applied.
  Future<bool> isEnabled() {
    throw UnimplementedError('isEnabled() has not been implemented.');
  }

  /// `true` while a recording/mirroring session is active (one-shot read).
  Future<bool> isCaptured() {
    throw UnimplementedError('isCaptured() has not been implemented.');
  }

  /// Emits whenever capture starts/stops, and on individual screenshots where
  /// supported.
  Stream<CaptureState> captureState() {
    throw UnimplementedError('captureState() has not been implemented.');
  }
}
