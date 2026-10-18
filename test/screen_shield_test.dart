import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:screen_shield/screen_shield.dart';
import 'package:screen_shield/screen_shield_method_channel.dart';
import 'package:screen_shield/screen_shield_platform_interface.dart';

class MockScreenShieldPlatform extends ScreenShieldPlatform
    with MockPlatformInterfaceMixin {
  final List<String> calls = <String>[];
  bool enabled = false;
  bool captured = false;

  @override
  Future<void> enable() async {
    calls.add('enable');
    enabled = true;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    enabled = false;
  }

  @override
  Future<void> suspend() async => calls.add('suspend');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> isCaptured() async => captured;

  @override
  Stream<CaptureState> captureState() => const Stream<CaptureState>.empty();
}

void main() {
  final ScreenShieldPlatform initialPlatform = ScreenShieldPlatform.instance;

  test('$MethodChannelScreenShield is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenShield>());
  });

  test('ScreenShield delegates commands to the platform instance', () async {
    final mock = MockScreenShieldPlatform();
    ScreenShieldPlatform.instance = mock;

    await ScreenShield.enable();
    expect(await ScreenShield.isEnabled, isTrue);
    await ScreenShield.disable();
    expect(await ScreenShield.isEnabled, isFalse);
    await ScreenShield.suspend();
    await ScreenShield.resume();

    expect(mock.calls, ['enable', 'disable', 'suspend', 'resume']);
  });

  test('ScreenShield surfaces isCaptured from the platform instance', () async {
    final mock = MockScreenShieldPlatform()..captured = true;
    ScreenShieldPlatform.instance = mock;

    expect(await ScreenShield.isCaptured, isTrue);
  });
}
