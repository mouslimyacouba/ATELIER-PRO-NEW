import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/models/order.dart';

void main() {
  group('Payment Overpayment & Boundary Tests', () {
    test('Payment exact balance calculation', () {
      final order = AtelierOrder(
        id: 'o1',
        userId: 'u1',
        clientId: 'c1',
        description: 'Tenue de mariage',
        status: OrderStatus.enCours,
        dateCommande: DateTime.now(),
        prixTotal: 50000,
        acompte: 30000,
        createdAt: DateTime.now(),
      );

      expect(order.remaining, equals(20000.0));
      expect(order.isFullyPaid, isFalse);

      // Saisie d'un paiement exact de 20 000
      final newAcompte = order.acompte + 20000;
      final updatedOrder = AtelierOrder(
        id: order.id,
        userId: order.userId,
        clientId: order.clientId,
        description: order.description,
        status: order.status,
        dateCommande: order.dateCommande,
        prixTotal: order.prixTotal,
        acompte: newAcompte,
        createdAt: order.createdAt,
      );

      expect(updatedOrder.remaining, equals(0.0));
      expect(updatedOrder.isFullyPaid, isTrue);
    });

    test('Overpayment detection logic rejects amounts greater than remaining balance', () {
      final order = AtelierOrder(
        id: 'o1',
        userId: 'u1',
        clientId: 'c1',
        description: 'Tenue de mariage',
        status: OrderStatus.enCours,
        dateCommande: DateTime.now(),
        prixTotal: 50000,
        acompte: 40000,
        createdAt: DateTime.now(),
      );

      final remaining = order.remaining; // 10 000 FCFA
      expect(remaining, equals(10000.0));

      double paymentAttempt = 15000.0;
      bool isValidPayment = paymentAttempt > 0 && paymentAttempt <= remaining;
      expect(isValidPayment, isFalse);

      paymentAttempt = 10000.0;
      isValidPayment = paymentAttempt > 0 && paymentAttempt <= remaining;
      expect(isValidPayment, isTrue);

      paymentAttempt = 0.0;
      isValidPayment = paymentAttempt > 0 && paymentAttempt <= remaining;
      expect(isValidPayment, isFalse);
    });
  });
}
