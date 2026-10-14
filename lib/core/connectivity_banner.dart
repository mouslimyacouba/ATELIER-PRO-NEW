import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sync_status.dart';
import 'theme.dart';

/// Petit bandeau affiché en haut de l'écran quand l'appareil est hors ligne.
/// Purement informatif : l'app continue de fonctionner normalement grâce au
/// cache local Firestore (lecture ET écriture), ce bandeau sert juste à
/// rassurer l'utilisateur que ses actions seront bien synchronisées.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hasPendingWrites = context.watch<SyncStatus>().hasPending;
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final offline = results != null &&
            results.isNotEmpty &&
            results.every((r) => r == ConnectivityResult.none);

        if (!offline && !hasPendingWrites) return const SizedBox.shrink();

        return Column(
          children: [
            if (offline)
              _ConnectivityMessage(
                icon: Icons.wifi_off_rounded,
                color: AtelierProColors.primaryContainer,
                foreground: colors.onPrimary,
                message: 'Mode hors-ligne — Vos modifications sont enregistrées '
                    'localement et seront synchronisées.',
              ),
            if (hasPendingWrites)
              _ConnectivityMessage(
                icon: Icons.cloud_upload_outlined,
                color: colors.secondaryContainer,
                foreground: colors.onSecondaryContainer,
                message: 'Envoi en attente — vos données sont enregistrées sur '
                    'le téléphone.',
              ),
          ],
        );
      },
    );
  }
}

class _ConnectivityMessage extends StatelessWidget {
  const _ConnectivityMessage({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
