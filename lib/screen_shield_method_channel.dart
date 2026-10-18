import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_shield_platform_interface.dart';
import 'src/capture_state.dart';

/// An implementation of [ScreenShieldPlatform] that uses method and event
/// channels to talk to the native side.
class MethodChannelScreenShield extends ScreenShieldPlatform {
  /// The method channel used to issue commands to the native side.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_shield/method');

  /// The event channel used to receive capture-state events from native.
  @visibleForTesting
  final eventChannel = const EventChannel('screen_shield/event');

  @override
  Future<void> enable() => methodChannel.invokeMethod<void>('enable');

  @override
  Future<void> disable() => methodChannel.invokeMethod<void>('disable');

  @override
  Future<void> suspend() => methodChannel.invokeMethod<void>('suspend');

  @override
  Future<void> resume() => methodChannel.invokeMethod<void>('resume');

  @override
  Future<bool> isEnabled() async =>
      (await methodChannel.invokeMethod<dynamic>('isEnabled')) == true;

  @override
  Future<bool> isCaptured() async =>
      (await methodChannel.invokeMethod<dynamic>('isCaptured')) == true;

  @override
  Stream<CaptureState> captureState() =>
      eventChannel.receiveBroadcastStream().map(CaptureState.fromWire);
}
