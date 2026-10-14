import 'package:atelierpro_mobile/providers/atelier_provider.dart';
import 'package:atelierpro_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'support/fake_providers.dart';

Future<void> _pumpOnboarding(
  WidgetTester tester,
  FakeAtelierProvider atelier,
) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Accueil')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<AtelierProvider>.value(
      value: atelier,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirms the selected atelier name and trade neutrally',
      (tester) async {
    final atelier = FakeAtelierProvider(testAtelier());
    await _pumpOnboarding(tester, atelier);

    await tester.tap(find.text('Couture / Confection'));
    await tester.enterText(find.byType(TextFormField).first, 'Atelier Aminata');
    await tester.ensureVisible(find.text('Créer mon atelier'));
    await tester.tap(find.text('Créer mon atelier'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer le métier ?'), findsOneWidget);
    expect(
      find.text('Atelier « Atelier Aminata » : Couture / Confection.'),
      findsOneWidget,
    );
    expect(find.textContaining('définitif'), findsNothing);
    expect(find.textContaining('nouveau compte'), findsNothing);

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(atelier.createdName, 'Atelier Aminata');
    expect(atelier.createdSpecialite, 'Couture / Confection');
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('requires an explicit trade selection', (tester) async {
    await _pumpOnboarding(tester, FakeAtelierProvider(testAtelier()));

    await tester.enterText(find.byType(TextFormField).first, 'Atelier Aminata');
    await tester.ensureVisible(find.text('Créer mon atelier'));
    await tester.tap(find.text('Créer mon atelier'));
    await tester.pumpAndSettle();

    expect(find.text('Choisissez le métier de votre atelier.'), findsOneWidget);
    expect(find.text('Confirmer le métier ?'), findsNothing);
  });
}
