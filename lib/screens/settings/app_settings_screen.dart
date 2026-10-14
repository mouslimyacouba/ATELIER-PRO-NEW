import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notification_service.dart';
import '../../providers/orders_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/settings_group.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key, this.onNotificationsChanged});

  final Future<void> Function()? onNotificationsChanged;

  Future<void> _applyNotificationChange(BuildContext context) async {
    final apply = onNotificationsChanged;
    if (apply != null) {
      await apply();
      return;
    }
    await NotificationService.syncReminders(
      context.read<OrdersProvider>().orders,
      force: true,
    );
  }

  Future<void> _setNotifications(BuildContext context, bool enabled) async {
    try {
      await context.read<SettingsProvider>().setNotificationsEnabled(enabled);
      if (!context.mounted) return;
      await _applyNotificationChange(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de mettre à jour les rappels : $error'),
        ),
      );
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/parametres');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final mode = themeProvider.themeMode;
    final modeLabel = switch (mode) {
      ThemeMode.system => 'Système',
      ThemeMode.light => 'Clair',
      ThemeMode.dark => 'Sombre',
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _goBack(context),
                  tooltip: 'Retour',
                  icon: const Icon(Icons.arrow_back),
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Paramètres',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATELIERPRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paramètres',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choisissez l'apparence de l'application et vos rappels "
                    'de livraison.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SettingsSectionLabel(
              'Thème',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Thème $modeLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ThemeCard(
                    icon: Icons.brightness_auto_outlined,
                    label: 'Système',
                    selected: mode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeCard(
                    icon: Icons.light_mode_outlined,
                    label: 'Clair',
                    selected: mode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeCard(
                    icon: Icons.dark_mode_outlined,
                    label: 'Sombre',
                    selected: mode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Text(
                'Système : suit le réglage de votre téléphone. Le choix est '
                'conservé à la prochaine ouverture.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SettingsSectionLabel('Notifications'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Rappels de livraison',
                  subtitle: 'La veille et le jour de la livraison, à 8 h, et '
                      'pour les commandes en retard.',
                  onTap: () => _setNotifications(
                    context,
                    !settings.notificationsEnabled,
                  ),
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (value) => _setNotifications(context, value),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Text(
                'Si vous ne recevez rien, vérifiez que les notifications sont '
                'autorisées pour AtelierPro dans les réglages du téléphone.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SettingsSectionLabel('Données'),
            const SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.cloud_done_outlined,
                  title: 'Fonctionnement hors ligne',
                  subtitle: 'Vos saisies sont enregistrées sur le téléphone '
                      'et envoyées dès que la connexion revient.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected ? colors.primary : colors.outline,
        width: selected ? 2 : 1,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: 'Thème $label',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? colors.primaryContainer : colors.surfaceContainer,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                      ),
                      child: Icon(icon, size: 20, color: colors.primary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: selected ? colors.primary : colors.outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
