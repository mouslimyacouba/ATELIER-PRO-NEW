import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/models/order.dart';

void main() {
  group('Orders Offline Calculation & Logic Tests', () {
    test('Local order sequence computation works as expected', () {
      final orders = [
        AtelierOrder(
          id: '1',
          userId: 'user1',
          clientId: 'client1',
          description: 'Commande 1',
          status: OrderStatus.enCours,
          dateCommande: DateTime.now(),
          prixTotal: 10000,
          acompte: 5000,
          createdAt: DateTime.now(),
          numero: 1,
        ),
        AtelierOrder(
          id: '2',
          userId: 'user1',
          clientId: 'client1',
          description: 'Commande 2',
          status: OrderStatus.enAttente,
          dateCommande: DateTime.now(),
          prixTotal: 25000,
          acompte: 10000,
          createdAt: DateTime.now(),
          numero: 5,
        ),
      ];

      final maxNumeroActuel = orders.fold<int>(
        0,
        (maxVal, o) => (o.numero ?? 0) > maxVal ? (o.numero ?? 0) : maxVal,
      );
      final nouveauNumeroLocal = maxNumeroActuel + 1;

      expect(maxNumeroActuel, equals(5));
      expect(nouveauNumeroLocal, equals(6));
    });

    test('Order calculation getters correctly compute totals and remaining balances', () {
      final orders = [
        AtelierOrder(
          id: '1',
          userId: 'user1',
          clientId: 'c1',
          description: 'Commande 1',
          status: OrderStatus.enCours,
          dateCommande: DateTime.now(),
          prixTotal: 50000,
          acompte: 20000,
          createdAt: DateTime.now(),
        ),
        AtelierOrder(
          id: '2',
          userId: 'user1',
          clientId: 'c2',
          description: 'Commande 2',
          status: OrderStatus.termine,
          dateCommande: DateTime.now(),
          prixTotal: 30000,
          acompte: 30000,
          createdAt: DateTime.now(),
        ),
      ];

      final totalCA = orders.fold<double>(0, (sum, o) => sum + o.prixTotal);
      final totalRemaining = orders.fold<double>(0, (sum, o) => sum + o.remaining);

      expect(totalCA, equals(80000.0));
      expect(totalRemaining, equals(30000.0));
    });
  });
}
