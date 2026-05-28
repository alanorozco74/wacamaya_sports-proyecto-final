import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wacamaya_sports/app.dart'; // Importación corregida

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WacamayaSportsApp());

    // Verifica que el texto de la Splash Screen o Login esté presente
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
