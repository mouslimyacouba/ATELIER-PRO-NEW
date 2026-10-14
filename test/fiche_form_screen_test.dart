import 'package:atelierpro_mobile/providers/atelier_provider.dart';
import 'package:atelierpro_mobile/providers/clients_provider.dart';
import 'package:atelierpro_mobile/providers/fiches_mesures_provider.dart';
import 'package:atelierpro_mobile/screens/mesures/fiche_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'support/fake_providers.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  required FakeClientsProvider clients,
  required FakeFichesMesuresProvider fiches,
  String location = '/fiche-form',
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Accueil')),
      ),
      GoRoute(
        path: '/clients/nouveau',
        builder: (context, state) =>
            const Scaffold(body: Text('Écran nouveau client')),
      ),
      GoRoute(
        path: '/fiche-form',
        builder: (context, state) => FicheFormScreen(
          initialClientId: state.uri.queryParameters['clientId'],
        ),
      ),
      GoRoute(
        path: '/fiche-form/:ficheId',
        builder: (context, state) => FicheFormScreen(
          ficheId: state.pathParameters['ficheId'],
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AtelierProvider>.value(
          value: FakeAtelierProvider(testAtelier()),
        ),
        ChangeNotifierProvider<ClientsProvider>.value(value: clients),
        ChangeNotifierProvider<FichesMesuresProvider>.value(value: fiches),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prefills client and rejects a zero measurement', (tester) async {
    final clients = FakeClientsProvider(initialClients: [testClient()]);
    final fiches = FakeFichesMesuresProvider();
    await _pumpForm(
      tester,
      clients: clients,
      fiches: fiches,
      location: '/fiche-form?clientId=client-1',
    );

    expect(find.text('Nouvelle fiche de mesures'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Enregistrer la fiche'));
    await tester.pumpAndSettle();

    expect(find.text('Entrez un nombre valide.'), findsOneWidget);
    expect(fiches.addedFiche, isNull);
  });

  testWidgets('opens an existing sheet read-only, then merges edits',
      (tester) async {
    final clients = FakeClientsProvider(initialClients: [testClient()]);
    final fiche = testFiche(
      mesures: const {'tour_taille': 88.0, 'legacy_field': 'conservé'},
    );
    final fiches = FakeFichesMesuresProvider(initialFiches: [fiche]);
    await _pumpForm(
      tester,
      clients: clients,
      fiches: fiches,
      location: '/fiche-form/fiche-1',
    );

    expect(find.text('Fiche de mesures'), findsOneWidget);
    final measureField = tester.widget<EditableText>(
      find.byType(EditableText).at(2),
    );
    expect(measureField.readOnly, isTrue);
    expect(measureField.controller.text, '88');

    await tester.tap(find.text('Modifier la fiche'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '92,5');
    await tester.tap(find.text('Enregistrer la fiche'));
    await tester.pumpAndSettle();

    expect(fiches.updatedFicheId, 'fiche-1');
    final merged = fiches.updatedChanges?['mesures'] as Map<String, dynamic>;
    expect(merged['tour_taille'], 92.5);
    expect(merged['legacy_field'], 'conservé');
  });

  testWidgets('offers client creation when no clients exist', (tester) async {
    await _pumpForm(
      tester,
      clients: FakeClientsProvider(),
      fiches: FakeFichesMesuresProvider(),
    );

    expect(find.text('Ajoutez un client avant de créer sa fiche.'),
        findsOneWidget);
    await tester.tap(find.text('Ajouter un client'));
    await tester.pumpAndSettle();
    expect(find.text('Écran nouveau client'), findsOneWidget);
  });
}
