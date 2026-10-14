import 'package:flutter/material.dart';

class MetierInfoTile extends StatelessWidget {
  const MetierInfoTile({
    required this.metier,
    super.key,
  });

  final String metier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            'Métier',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metier,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
