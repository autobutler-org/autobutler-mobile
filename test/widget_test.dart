// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:autobutler/main.dart';

void main() {
  testWidgets('renders file browser screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AutobutlerApp());
    await tester.pumpAndSettle();

    expect(find.text('Cirrus'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Size'), findsOneWidget);
    expect(find.text('flipped_(1).jpg'), findsOneWidget);
  });
}
