import 'package:atelierpro_mobile/core/reminder_signature.dart';
import 'package:atelierpro_mobile/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

AtelierOrder _order({
  OrderStatus status = OrderStatus.enAttente,
  DateTime? dueDate,
}) {
  final now = DateTime(2026, 10, 13);
  return AtelierOrder(
    id: 'order-1',
    userId: 'user-1',
    clientId: 'client-1',
    description: 'Commande',
    status: status,
    dateCommande: now,
    dateEcheance: dueDate,
    prixTotal: 1000,
    acompte: 0,
    createdAt: now,
  );
}

void main() {
  test('signature changes with the day, order status, or due date', () {
    final now = DateTime(2026, 10, 13, 9);
    final baseline = reminderSignature([_order()], now);

    expect(
        reminderSignature([_order()], DateTime(2026, 10, 14)), isNot(baseline));
    expect(
      reminderSignature([_order(status: OrderStatus.enCours)], now),
      isNot(baseline),
    );
    expect(
      reminderSignature([_order(dueDate: DateTime(2026, 10, 20))], now),
      isNot(baseline),
    );
  });
}
