import 'package:flutter_test/flutter_test.dart';
import 'package:android_claw/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AndroidClawApp());
    expect(find.text('AndroidClaw'), findsOneWidget);
  });
}
