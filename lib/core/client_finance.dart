import '../models/order.dart';

/// Résumé financier calculé depuis les montants enregistrés sur les commandes.
///
/// `acompte` inclut l'acompte initial et les paiements ultérieurs. Les documents
/// de paiement ne sont donc pas additionnés une seconde fois.
class ClientFinanceSummary {
  const ClientFinanceSummary({
    required this.orderCount,
    required this.cancelledCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.overpaidAmount,
    required this.invalidOrderCount,
  });

  factory ClientFinanceSummary.fromOrders(Iterable<AtelierOrder> orders) {
    var orderCount = 0;
    var cancelledCount = 0;
    var total = 0.0;
    var paid = 0.0;
    var remaining = 0.0;
    var overpaid = 0.0;
    var invalid = 0;

    for (final order in orders) {
      if (order.status == OrderStatus.annule) {
        cancelledCount++;
        continue;
      }
      if (!order.hasValidFinancialData ||
          !order.prixTotal.isFinite ||
          order.prixTotal < 0 ||
          !order.acompte.isFinite ||
          order.acompte < 0) {
        invalid++;
        continue;
      }

      orderCount++;
      total += order.prixTotal;
      paid += order.acompte;
      remaining += order.remaining;
      overpaid +=
          (order.acompte - order.prixTotal).clamp(0, double.infinity).toDouble();
    }

    return ClientFinanceSummary(
      orderCount: orderCount,
      cancelledCount: cancelledCount,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: remaining,
      overpaidAmount: overpaid,
      invalidOrderCount: invalid,
    );
  }

  final int orderCount;
  final int cancelledCount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double overpaidAmount;
  final int invalidOrderCount;

  bool get hasOrders => orderCount > 0;
  bool get isSettled => hasOrders && remainingAmount <= 0;
}
