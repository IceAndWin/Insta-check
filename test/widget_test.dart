import 'package:flutter_test/flutter_test.dart';
import 'package:insta_check/app/app.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaCheckApp());
    expect(find.byType(InstaCheckApp), findsOneWidget);
  });
}
