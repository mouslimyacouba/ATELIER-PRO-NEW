import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class LockedMetierTile extends StatelessWidget {
  const LockedMetierTile({
    required this.metier,
    super.key,
  });

  final String metier;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.work_outline,
        color: AtelierProColors.primary,
      ),
      title: const Text('Métier de l’atelier'),
      subtitle: Text(
        '$metier\nChoix définitif pour ce compte.',
        style: const TextStyle(height: 1.4),
      ),
      isThreeLine: true,
      trailing: const Icon(
        Icons.lock_outline,
        size: 18,
        color: AtelierProColors.onSurfaceMuted,
      ),
    );
  }
}
