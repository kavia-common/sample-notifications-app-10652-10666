import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_notifications_frontend/main.dart';

void main() {
  testWidgets('App renders a scaffold with title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // AppBar title
    expect(find.text('sample_notifications_frontend'), findsOneWidget);

    // Body headline text
    expect(find.text('sample_notifications_frontend'), findsWidgets);
  });

  testWidgets('Shows progress indicator while initializing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initial frame shows loading spinner before async init completes.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
