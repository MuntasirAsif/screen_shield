import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_shield_example/main.dart';

void main() {
  testWidgets('renders the shield controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('screen_shield example'), findsOneWidget);
    expect(find.text('Block screenshots & recording'), findsOneWidget);
    expect(find.text('Open the file picker'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
