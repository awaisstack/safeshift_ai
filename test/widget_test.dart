import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeshift_ai/app.dart';

void main() {
  testWidgets('SafeShiftApp Onboarding Screen basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SafeShiftApp());

    // Verify that onboarding screen loads.
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Find either start button or onboarding title text
    expect(find.textContaining('SafeShift AI'), findsAtLeast(1));
  });
}