import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celesmile/main.dart';

void main() {
  testWidgets('App launches with Welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CelesmileApp());

    // Verify that Welcome screen is displayed
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Celesmile'), findsOneWidget);
    expect(find.text('スキップ'), findsOneWidget);
  });

  testWidgets('Navigate to phone verification screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CelesmileApp());

    // Tap the skip button
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();

    // Verify that phone verification screen is displayed
    expect(find.text('電話番号の確認'), findsOneWidget);
  });
}
