// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wait_wise/main.dart';

void main() {
  testWidgets('App starts and shows home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the home page is displayed
    expect(find.text('Welcome to waitwise'), findsOneWidget);
    expect(find.text('Join the virtual line and track your turn in real time.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
