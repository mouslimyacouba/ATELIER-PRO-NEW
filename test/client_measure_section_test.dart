import 'package:atelierpro_mobile/models/fiche_mesure.dart';
import 'package:atelierpro_mobile/providers/fiches_mesures_provider.dart';
import 'package:atelierpro_mobile/screens/clients/widgets/client_measure_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FicheMesure _fiche(String id, String clientId, String title) {
  final now = DateTime(2026);
  return FicheMesure(
    id: id,
    userId: 'owner',
    clientId: clientId,
    titre: title,
    mesures: const {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('filters measure sheets by client id', () {
    final visible = filterFichesForClient(
      [_fiche('1', 'client-a', 'A'), _fiche('2', 'client-b', 'B')],
      'client-a',
    );

    expect(visible.map((fiche) => fiche.id), ['1']);
  });

  testWidgets('shows an empty state and client-filter navigation',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientMeasureSection(
            fiches: const [],
            loading: false,
            error: null,
            onRetry: () {},
            onAdd: () {},
            onOpenAll: () => opened = true,
            onOpenFiche: (_) {},
          ),
        ),
      ),
    );

    expect(
        find.text('Aucune fiche de mesures pour ce client.'), findsOneWidget);
    await tester.tap(find.text('Voir tout'));
    expect(opened, isTrue);
  });

  testWidgets('shows filtered sheet titles and loading or error feedback',
      (tester) async {
    final fiche = _fiche('1', 'client-a', 'Fiche boubou');
    var openedFiche = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientMeasureSection(
            fiches: [fiche],
            loading: false,
            error: null,
            onRetry: () {},
            onAdd: () {},
            onOpenAll: () {},
            onOpenFiche: (value) => openedFiche = value.id,
          ),
        ),
      ),
    );
    expect(find.text('Fiche boubou'), findsOneWidget);
    await tester.tap(find.text('Fiche boubou'));
    expect(openedFiche, '1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientMeasureSection(
            fiches: const [],
            loading: true,
            error: null,
            onRetry: () {},
            onAdd: () {},
            onOpenAll: () {},
            onOpenFiche: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientMeasureSection(
            fiches: const [],
            loading: false,
            error: 'Erreur de chargement',
            onRetry: () {},
            onAdd: () {},
            onOpenAll: () {},
            onOpenFiche: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Erreur de chargement'), findsOneWidget);
  });
}
