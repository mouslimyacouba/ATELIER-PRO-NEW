import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atelierpro_mobile/core/client_finance.dart';
import 'package:atelierpro_mobile/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

AtelierOrder _order({
  required String id,
  required double total,
  required double paid,
  OrderStatus status = OrderStatus.enCours,
}) {
  final now = DateTime(2026);
  return AtelierOrder(
    id: id,
    userId: 'owner',
    clientId: 'client',
    description: 'Commande $id',
    status: status,
    dateCommande: now,
    prixTotal: total,
    acompte: paid,
    createdAt: now,
  );
}

void main() {
  group('ClientFinanceSummary', () {
    test('returns zero amounts for an empty order list', () {
      final summary = ClientFinanceSummary.fromOrders(const []);

      expect(summary.orderCount, 0);
      expect(summary.cancelledCount, 0);
      expect(summary.totalAmount, 0);
      expect(summary.paidAmount, 0);
      expect(summary.remainingAmount, 0);
      expect(summary.hasOrders, isFalse);
      expect(summary.isSettled, isFalse);
    });

    test('sums paid amounts once and remaining per order', () {
      final summary = ClientFinanceSummary.fromOrders([
        _order(id: 'partial', total: 100, paid: 30),
        _order(id: 'paid', total: 50, paid: 50),
      ]);

      expect(summary.orderCount, 2);
      expect(summary.totalAmount, 150);
      expect(summary.paidAmount, 80);
      expect(summary.remainingAmount, 70);
      expect(summary.isSettled, isFalse);
    });

    test('excludes cancelled orders from all financial amounts', () {
      final summary = ClientFinanceSummary.fromOrders([
        _order(id: 'active', total: 100, paid: 25),
        _order(
          id: 'cancelled',
          total: 500,
          paid: 300,
          status: OrderStatus.annule,
        ),
      ]);

      expect(summary.orderCount, 1);
      expect(summary.cancelledCount, 1);
      expect(summary.totalAmount, 100);
      expect(summary.paidAmount, 25);
      expect(summary.remainingAmount, 75);
    });

    test('overpayment is visible but cannot reduce another order balance', () {
      final summary = ClientFinanceSummary.fromOrders([
        _order(id: 'overpaid', total: 50, paid: 70),
        _order(id: 'partial', total: 100, paid: 20),
      ]);

      expect(summary.paidAmount, 90);
      expect(summary.remainingAmount, 80);
      expect(summary.overpaidAmount, 20);
    });

    test('excludes invalid financial records and reports their count', () {
      final summary = ClientFinanceSummary.fromOrders([
        _order(id: 'valid', total: 100, paid: 20),
        _order(id: 'invalid', total: double.nan, paid: 10),
      ]);

      expect(summary.orderCount, 1);
      expect(summary.invalidOrderCount, 1);
      expect(summary.totalAmount, 100);
      expect(summary.paidAmount, 20);
      expect(summary.remainingAmount, 80);
    });

    test('missing financial fields do not crash order loading or inflate totals',
        () {
      final order = AtelierOrder.fromMap('legacy-missing-money', {
        'userId': 'owner',
        'clientId': 'client',
        'description': 'Commande historique incomplète',
        'statut': 'en_cours',
        'dateCommande': Timestamp.fromDate(DateTime(2026)),
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      });
      final summary = ClientFinanceSummary.fromOrders([order]);

      expect(order.hasValidFinancialData, isFalse);
      expect(summary.orderCount, 0);
      expect(summary.invalidOrderCount, 1);
      expect(summary.totalAmount, 0);
      expect(summary.paidAmount, 0);
    });
  });
}
