import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:screen_shield/screen_shield.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('enable / disable round-trips through the platform',
      (WidgetTester tester) async {
    await ScreenShield.enable();
    expect(await ScreenShield.isEnabled, isTrue);

    await ScreenShield.disable();
    expect(await ScreenShield.isEnabled, isFalse);

    // Leave protection on for manual verification on the device.
    await ScreenShield.enable();
  });
}
