// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nextshift/widgets/Heading.dart';

void main() {
  testWidgets('Heading renders uppercase text at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Heading(text: 'Next Shift', size: 30),
      ),
    );

    final text = tester.widget<Text>(find.text('NEXT SHIFT'));
    expect(text.style?.fontSize, 30);
  });
}
