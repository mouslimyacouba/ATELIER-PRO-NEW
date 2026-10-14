import 'dart:async';

import 'package:atelierpro_mobile/providers/atelier_provider.dart';
import 'package:atelierpro_mobile/providers/clients_provider.dart';
import 'package:atelierpro_mobile/screens/clients/client_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'support/fake_providers.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  required FakeClientsProvider clients,
  String location = '/client-form',
  bool openFromHome = false,
}) async {
  final router = GoRouter(
    initialLocation: openFromHome ? '/home' : location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: openFromHome
              ? TextButton(
                  onPressed: () => context.push('/client-form'),
                  child: const Text('Ouvrir le formulaire'),
                )
              : const Text('Accueil'),
        ),
      ),
      GoRoute(
        path: '/client-form',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/client-form/:clientId',
        builder: (context, state) => ClientFormScreen(
          clientId: state.pathParameters['clientId'],
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
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates required name and optional eight-digit phone',
      (tester) async {
    final clients = FakeClientsProvider();
    await _pumpForm(tester, clients: clients);

    await tester.tap(find.text('Enregistrer le client'));
    await tester.pumpAndSettle();
    expect(find.text('Le nom est obligatoire.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Client test');
    await tester.enterText(find.byType(TextFormField).at(1), '9012345');
    await tester.tap(find.text('Enregistrer le client'));
    await tester.pumpAndSettle();

    expect(find.text('Le numéro doit avoir 8 chiffres.'), findsOneWidget);
    expect(clients.addCalls, 0);
  });

  testWidgets('warns before saving a duplicate phone number', (tester) async {
    final clients = FakeClientsProvider(
      initialClients: [testClient(id: 'other', name: 'Autre client')],
    );
    await _pumpForm(tester, clients: clients);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nouveau client');
    await tester.enterText(find.byType(TextFormField).at(1), '90 00 00 00');
    await tester.tap(find.text('Enregistrer le client'));
    await tester.pumpAndSettle();

    expect(find.text('Ce numéro existe déjà'), findsOneWidget);
    expect(clients.addCalls, 0);
    await tester.tap(find.text('Enregistrer quand même'));
    await tester.pumpAndSettle();
    expect(clients.addCalls, 1);
  });

  testWidgets('confirms abandonment of an unsaved form', (tester) async {
    await _pumpForm(
      tester,
      clients: FakeClientsProvider(),
      openFromHome: true,
    );
    await tester.tap(find.text('Ouvrir le formulaire'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Client test');
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner la saisie ?'), findsOneWidget);
    await tester.tap(find.text('Continuer la saisie'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau client'), findsOneWidget);
    expect(find.byType(TextFormField).first, findsOneWidget);
  });

  testWidgets('pre-fills edit data and preserves the existing client id',
      (tester) async {
    final existing = testClient();
    final clients = FakeClientsProvider(initialClients: [existing]);
    await _pumpForm(
      tester,
      clients: clients,
      location: '/client-form/client-1',
    );

    expect(find.text('Modifier le client'), findsOneWidget);
    expect(
        (tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!)
            .text,
        'Aminata');
    await tester.enterText(find.byType(TextFormField).first, 'Aminata Diallo');
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();

    expect(clients.updateId, 'client-1');
    expect(clients.updateChanges?['nom_complet'], 'Aminata Diallo');
    expect(clients.addCalls, 0);
  });

  testWidgets('keeps fields and reports save failures', (tester) async {
    final clients = FakeClientsProvider()
      ..onAdd = (_) async => 'Échec Firestore';
    await _pumpForm(tester, clients: clients);
    await tester.enterText(find.byType(TextFormField).first, 'Client test');
    await tester.tap(find.text('Enregistrer le client'));
    await tester.pumpAndSettle();

    expect(find.text('Échec Firestore'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Client test',
    );
  });

  testWidgets('disables repeated submission while a save is pending',
      (tester) async {
    final completer = Completer<String?>();
    final clients = FakeClientsProvider()..onAdd = (_) => completer.future;
    await _pumpForm(tester, clients: clients);
    await tester.enterText(find.byType(TextFormField).first, 'Client test');

    await tester.tap(find.text('Enregistrer le client'));
    await tester.pump();
    expect(clients.addCalls, 1);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    completer.complete(null);
    await tester.pumpAndSettle();
    expect(clients.addCalls, 1);
  });

  testWidgets('keeps fields when a provider throws unexpectedly',
      (tester) async {
    final clients = FakeClientsProvider()
      ..onAdd = (_) async => throw StateError('Erreur inattendue');
    await _pumpForm(tester, clients: clients);
    await tester.enterText(find.byType(TextFormField).first, 'Client test');
    await tester.tap(find.text('Enregistrer le client'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur inattendue'), findsOneWidget);
    expect(find.text('Nouveau client'), findsOneWidget);
  });
}
