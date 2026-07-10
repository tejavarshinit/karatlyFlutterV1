import 'package:flutter_test/flutter_test.dart';
import 'package:karatly/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaratlyApp());
    await tester.pumpAndSettle();
  });
}
