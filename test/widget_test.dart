// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_portal/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PatientPortalApp());

    // Verify that our app starts correctly
    expect(find.text('MedSys'), findsOneWidget);
  });
}