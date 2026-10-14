import 'package:flutter/material.dart';

import '../../../core/currency_formatter.dart';
import '../../../core/theme.dart';
import '../../../core/client_finance.dart';

class ClientFinanceCard extends StatelessWidget {
  const ClientFinanceCard({super.key, required this.summary});

  final ClientFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settledColor = Theme.of(context).brightness == Brightness.dark
        ? AtelierProColors.tertiaryFixedDim
        : AtelierProColors.vertSucces;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Situation financière',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Total des commandes',
                    value: CurrencyFormatter.format(summary.totalAmount),
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(
                    label: 'Déjà payé',
                    value: CurrencyFormatter.format(summary.paidAmount),
                    color: settledColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _Metric(
              label: 'Reste à payer',
              value: CurrencyFormatter.format(summary.remainingAmount),
              color: summary.isSettled ? settledColor : colorScheme.primary,
              large: true,
            ),
            if (summary.overpaidAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Avance enregistrée : ${CurrencyFormatter.format(summary.overpaidAmount)}',
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (summary.invalidOrderCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${summary.invalidOrderCount} commande(s) avec des montants incohérents '
                'exclue(s) du calcul.',
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
            if (summary.cancelledCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${summary.cancelledCount} commande(s) annulée(s) exclue(s).',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AtelierProTheme.currencyDisplayStyle(
            fontSize: large ? 22 : 16,
            color: color,
            brightness: Theme.of(context).brightness,
          ),
        ),
      ],
    );
  }
}
