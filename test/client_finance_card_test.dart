import 'package:atelierpro_mobile/core/client_finance.dart';
import 'package:atelierpro_mobile/models/order.dart';
import 'package:atelierpro_mobile/screens/clients/widgets/client_finance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('financial card renders at narrow width in both themes',
      (tester) async {
    final now = DateTime(2026);
    final summary = ClientFinanceSummary.fromOrders([
      AtelierOrder(
        id: 'order-1',
        userId: 'owner',
        clientId: 'client',
        description: 'Commande',
        status: OrderStatus.enCours,
        dateCommande: now,
        prixTotal: 50000,
        acompte: 20000,
        createdAt: now,
      ),
    ]);

    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                child: ClientFinanceCard(summary: summary),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total des commandes'), findsOneWidget);
      expect(find.text('Déjà payé'), findsOneWidget);
      expect(find.text('Reste à payer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
