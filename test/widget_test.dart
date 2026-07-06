import 'package:flutter_test/flutter_test.dart';

import 'package:botum/app/app.dart';

void main() {
  testWidgets('App should render welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BotumApp());
    expect(find.text('Botum'), findsOneWidget);
  });
}
