import '../models/order.dart';

String reminderSignature(List<AtelierOrder> orders, DateTime now) {
  final day = now.toIso8601String().substring(0, 10);
  final orderSignature = orders
      .map(
        (order) =>
            '${order.id}:${order.status.name}:'
            '${order.dateEcheance?.millisecondsSinceEpoch}',
      )
      .join(',');
  return '$day|$orderSignature';
}
