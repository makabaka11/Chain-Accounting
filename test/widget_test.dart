import 'package:flutter_test/flutter_test.dart';
import 'package:chain_accounting/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ChainAccountingApp());
    await tester.pump();
    expect(find.text('Chain Accounting'), findsOneWidget);
  });
}
