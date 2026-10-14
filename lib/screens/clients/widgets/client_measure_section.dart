import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/fiche_mesure.dart';

final _measureDate = DateFormat('dd/MM/yyyy');

class ClientMeasureSection extends StatelessWidget {
  const ClientMeasureSection({
    super.key,
    required this.fiches,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onAdd,
    required this.onOpenAll,
    required this.onOpenFiche,
  });

  final List<FicheMesure> fiches;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final VoidCallback onOpenAll;
  final ValueChanged<FicheMesure> onOpenFiche;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Fiches de mesures',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: 'Nouvelle fiche',
              icon: const Icon(Icons.add),
            ),
            TextButton(
              onPressed: onOpenAll,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        if (loading && fiches.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          )
        else if (error != null && fiches.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(error!),
              trailing: IconButton(
                tooltip: 'Réessayer',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            ),
          )
        else if (fiches.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.straighten_outlined),
              title: Text('Aucune fiche de mesures pour ce client.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var index = 0; index < fiches.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.straighten_outlined,
                      color: AtelierProColors.terracotta,
                    ),
                    title: Text(
                      fiches[index].titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Modifiée le ${_measureDate.format(fiches[index].updatedAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpenFiche(fiches[index]),
                  ),
                ],
              ],
            ),
          ),
        if (error != null && fiches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Mise à jour des fiches impossible : $error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
