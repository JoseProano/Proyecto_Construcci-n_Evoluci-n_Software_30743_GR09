import 'package:flutter_test/flutter_test.dart';
import 'package:amazonfish/main.dart';

void main() {
  testWidgets('AmazonFish app loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const AmazonFishApp());
    expect(find.text('AmazonFish'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
