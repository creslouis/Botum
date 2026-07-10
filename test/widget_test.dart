import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botum/app/app.dart';
import 'package:botum/widgets/common/pink_button.dart';
import 'package:botum/widgets/common/custom_text_field.dart';

void main() {
  testWidgets('App should render welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BotumApp());
    expect(find.text('Botum'), findsOneWidget);
  });

  testWidgets('Shared widgets render their provided content', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PinkButton(text: 'Continue', onPressed: () {}),
              CustomTextField(hintText: 'Email', controller: controller),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
