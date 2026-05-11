import 'package:dbench/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders benchmark entry point', (tester) async {
    await tester.pumpWidget(const DbenchApp());

    expect(find.text('Dbench'), findsOneWidget);
    expect(
      find.text('Dart and Flutter local database benchmark'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Run benchmarks'), findsOneWidget);
  });
}
