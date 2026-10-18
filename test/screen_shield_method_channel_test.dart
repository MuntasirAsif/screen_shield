import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_shield/screen_shield.dart';
import 'package:screen_shield/screen_shield_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelScreenShield platform = MethodChannelScreenShield();
  const MethodChannel methodChannel = MethodChannel('screen_shield/method');
  const EventChannel eventChannel = EventChannel('screen_shield/event');

  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(methodChannel, (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'isEnabled':
          return true;
        case 'isCaptured':
          return false;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  test('dispatches commands over screen_shield/method', () async {
    await platform.enable();
    await platform.disable();
    await platform.suspend();
    await platform.resume();

    expect(
      calls.map((MethodCall call) => call.method).toList(),
      <String>['enable', 'disable', 'suspend', 'resume'],
    );
  });

  test('isEnabled and isCaptured read the method channel', () async {
    expect(await platform.isEnabled(), isTrue);
    expect(await platform.isCaptured(), isFalse);
  });

  test('captureState parses event-channel strings', () async {
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink sink) {
          sink.success('recording');
          sink.success('screenshot');
          sink.success('none');
        },
      ),
    );

    final List<CaptureState> received =
        await platform.captureState().take(3).toList();

    expect(received, <CaptureState>[
      CaptureState.recording,
      CaptureState.screenshot,
      CaptureState.none,
    ]);
  });
}
