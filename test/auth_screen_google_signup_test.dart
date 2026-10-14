import 'package:atelierpro_mobile/core/theme.dart';
import 'package:atelierpro_mobile/screens/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-up tab offers Google registration and active policy links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtelierProTheme.dark,
        home: const AuthScreen(),
      ),
    );

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("S'inscrire avec Google"));

    expect(find.text("S'inscrire avec Google"), findsOneWidget);
    expect(
      find.text('En continuant avec Google, vous acceptez les '),
      findsOneWidget,
    );
    expect(find.text("conditions d'utilisation"), findsOneWidget);
    expect(find.text('politique de confidentialité'), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
