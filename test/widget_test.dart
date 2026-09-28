import 'package:flutter_test/flutter_test.dart';
import 'package:stay_safe/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const StaySafeApp());
    expect(find.text('Stay Safe'), findsOneWidget);
  });
}
