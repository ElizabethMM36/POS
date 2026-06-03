import 'package:flutter_test/flutter_test.dart';

import 'package:my_pos_app/main.dart';

void main() {
  testWidgets('Login screen renders sign-in UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyPosApp());

    expect(find.text('Command Center POS'), findsOneWidget);
    expect(find.text('Staff sign-in'), findsOneWidget);
    expect(find.text('Authenticate'), findsOneWidget);
  });
}
