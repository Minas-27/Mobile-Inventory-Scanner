import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_scanner/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileInventoryApp());

    expect(find.text('Odoo ERP Login'), findsOneWidget);
  });
}
