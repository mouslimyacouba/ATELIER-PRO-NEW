import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/contact_actions.dart';
import '../../core/storage_service.dart';
import '../../models/atelier.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/auth_provider.dart';
import 'delete_account_dialogs.dart';
import 'widgets/metier_info_tile.dart';
import 'widgets/settings_group.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _supportPhone = '82199929';

  String _appVersion = '';
  bool _uploadingLogo = false;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Pas bloquant si indisponible (ex: web debug).
    }
  }

  Future<void> _changeLogo() async {
    final atelierProvider = context.read<AtelierProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final file = await StorageService.pickImage();
    if (!mounted || file == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final atelier = atelierProvider.atelier;
      if (atelier == null) return;
      final url = await StorageService.upload(
        bucket: 'logos',
        userId: atelier.userId,
        key: 'logo',
        file: file,
      );
      final error = await atelierProvider.updateLogo(url);
      if (mounted && error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Échec de l\'envoi : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _editAtelier() async {
    final atelier = context.read<AtelierProvider>().atelier;
    if (atelier == null) return;

    final nomCtrl = TextEditingController(text: atelier.nomAtelier);
    final telephoneCtrl = TextEditingController(text: atelier.telephone ?? '');
    final villeCtrl = TextEditingController(text: atelier.ville ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Modifier mon atelier',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nomCtrl,
                  decoration:
                      const InputDecoration(labelText: "Nom de l'atelier"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 10),
                MetierInfoTile(metier: atelier.specialiteLabel),
                const SizedBox(height: 10),
                TextFormField(
                  controller: telephoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '90 00 00 00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length != 8) {
                      return 'Le numéro doit avoir 8 chiffres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: villeCtrl,
                  decoration: const InputDecoration(labelText: 'Ville'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final error =
                        await context.read<AtelierProvider>().updateAtelier({
                      'nom_atelier': nomCtrl.text.trim(),
                      'telephone': telephoneCtrl.text.trim().isEmpty
                          ? null
                          : telephoneCtrl.text.trim(),
                      'ville': villeCtrl.text.trim().isEmpty
                          ? null
                          : villeCtrl.text.trim(),
                    });
                    if (ctx.mounted) {
                      if (error != null) {
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(SnackBar(content: Text(error)));
                      } else {
                        Navigator.of(ctx).pop(true);
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Atelier mis à jour')));
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Tu devras te reconnecter avec ton e-mail et ton mot de passe.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Se déconnecter',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _contactSupport() async {
    await openWhatsApp(_supportPhone,
        message: 'Bonjour, j\'ai besoin d\'aide avec AtelierPro Mobile.');
  }

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email;
    if (email == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Text(
          'Nous allons envoyer un lien de réinitialisation à $email. '
          'Ouvrez-le pour choisir un nouveau mot de passe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await auth.resetPasswordForEmail(email);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Lien envoyé à $email. Pensez à vérifier vos courriers '
                  'indésirables.',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    if (_deletingAccount) return;
    final confirmed = await showDeleteAccountConfirmation(context);
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final atelierProvider = context.read<AtelierProvider>();
      final recentLogin = await authProvider.hasRecentLogin();
      if (!mounted) return;

      if (!recentLogin) {
        if (authProvider.signInProviders.contains('password')) {
          final password = await showDeleteAccountPasswordDialog(context);
          if (password == null || !mounted) return;
          final error = await authProvider.reauthenticateWithPassword(password);
          if (error != null) {
            _showDeleteError(error);
            return;
          }
        } else {
          final reconnect = await showReloginBeforeDeleteDialog(context);
          if (reconnect != true || !mounted) return;
          await authProvider.signOut();
          return;
        }
      }

      final dataError = await atelierProvider.deleteAtelier();
      if (dataError != null) {
        _showDeleteError(dataError);
        return;
      }

      final accountError = await authProvider.deleteAccount();
      if (accountError != null) {
        _showDeleteError(accountError);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ton compte et tes données ont été supprimés.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showDeleteError(
          context.read<AuthProvider>().error ?? e.message ?? e.code,
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  void _showDeleteError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAccountInfo() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final providers = auth.signInProviders;
    final method = providers.contains('google.com')
        ? 'Google'
        : providers.contains('phone')
            ? 'Téléphone (code SMS)'
            : 'E-mail et mot de passe';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon compte', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              _AccountLine(label: 'Connexion', value: method),
              if (user?.email != null) ...[
                _AccountLine(label: 'Adresse e-mail', value: user!.email!),
                _AccountLine(
                  label: 'E-mail vérifié',
                  value: user.emailVerified ? 'Oui' : 'Non',
                ),
              ],
              if (user?.phoneNumber != null)
                _AccountLine(label: 'Téléphone', value: user!.phoneNumber!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtelierCard(Atelier? atelier) {
    final colors = Theme.of(context).colorScheme;
    final details = [
      atelier?.specialiteLabel,
      atelier?.ville,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    return SettingsGroup(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _editAtelier,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _uploadingLogo ? null : _changeLogo,
                    child: Semantics(
                      button: true,
                      label: "Changer le logo de l'atelier",
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: colors.surfaceContainerHighest,
                            backgroundImage: atelier?.logoUrl == null
                                ? null
                                : NetworkImage(atelier!.logoUrl!),
                            child: _uploadingLogo
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : atelier?.logoUrl == null
                                    ? Icon(
                                        Icons.storefront_outlined,
                                        color: colors.primary,
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 11,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          atelier?.nomAtelier ?? 'Mon atelier',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.outline),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final atelier = context.watch<AtelierProvider>().atelier;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final hasPassword = auth.signInProviders.contains('password');
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Réglages',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Votre atelier, votre compte et l'application",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _buildAtelierCard(atelier),
            const SettingsSectionLabel('Mon atelier'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.storefront_outlined,
                  title: "Informations de l'atelier",
                  subtitle: 'Nom, téléphone, ville, logo',
                  onTap: _editAtelier,
                ),
                SettingsRow(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Modèles de fabrication',
                  subtitle: 'Boubou homme, table en bois…',
                  onTap: () => context.push('/modeles'),
                ),
                SettingsRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock de matériel',
                  subtitle: 'Tissus, fils et fournitures',
                  onTap: () => context.push('/stock'),
                ),
              ],
            ),
            const SettingsSectionLabel('Compte'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.person_outline,
                  title: 'Mon compte',
                  subtitle: user?.email ?? user?.phoneNumber,
                  onTap: _showAccountInfo,
                ),
                if (hasPassword)
                  SettingsRow(
                    icon: Icons.lock_outline,
                    title: 'Changer le mot de passe',
                    subtitle: 'Un lien vous est envoyé par e-mail',
                    onTap: _changePassword,
                  ),
              ],
            ),
            const SettingsSectionLabel('Préférences'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  subtitle: 'Thème et notifications',
                  onTap: () => context.push('/parametres/preferences'),
                ),
                SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Confidentialité des données',
                  onTap: () => context.push('/parametres/confidentialite'),
                ),
                SettingsRow(
                  icon: Icons.description_outlined,
                  title: "Conditions d'utilisation",
                  onTap: () => context.push('/parametres/cgu'),
                ),
                SettingsRow(
                  icon: Icons.help_outline,
                  title: 'Aide / Support (WhatsApp)',
                  onTap: _contactSupport,
                ),
                SettingsRow(
                  icon: Icons.info_outline,
                  title: "À propos d'AtelierPro",
                  subtitle: _appVersion.isEmpty ? null : 'Version $_appVersion',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'AtelierPro',
                    applicationVersion: _appVersion,
                  ),
                ),
              ],
            ),
            const SettingsSectionLabel('Zone de danger'),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.logout,
                  title: 'Se déconnecter',
                  onTap: _confirmSignOut,
                ),
                SettingsRow(
                  icon: Icons.delete_outline,
                  title: 'Supprimer mon compte',
                  subtitle: 'Supprime votre compte et toutes vos données',
                  danger: true,
                  onTap: _deletingAccount ? null : _confirmDeleteAccount,
                  trailing: _deletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
            if (_appVersion.isNotEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'AtelierPro · v$_appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
