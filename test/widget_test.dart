// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:family_bank/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FamilyBankApp());

    // 等待初始化完成
    await tester.pumpAndSettle();

    // Verify that app title is displayed
    expect(find.text('账清'), findsOneWidget);
  });
}
