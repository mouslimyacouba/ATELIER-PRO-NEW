import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/form_validators.dart';
import '../../core/offline_save.dart';
import '../../core/sync_status.dart';
import '../../models/client.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/clients_provider.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.clientId});

  final String? clientId;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AtelierClient? _existing;
  bool _initialized = false;
  bool _loading = true;
  bool _notFound = false;
  bool _saving = false;
  bool _saved = false;
  String? _loadError;

  String _initialName = '';
  String _initialPhone = '';
  String _initialAddress = '';
  String _initialNotes = '';

  bool get _isEditing => widget.clientId != null;
  bool get _isDirty =>
      _nameCtrl.text != _initialName ||
      _phoneCtrl.text != _initialPhone ||
      _addressCtrl.text != _initialAddress ||
      _notesCtrl.text != _initialNotes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final atelier = context.read<AtelierProvider>().atelier;
    if (atelier == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Atelier introuvable. Réessayez après reconnexion.';
        });
      }
      return;
    }

    final provider = context.read<ClientsProvider>();
    await provider.load(atelier.userId);
    if (!mounted) return;

    if (_isEditing) {
      final client = provider.byId(widget.clientId!);
      if (client == null) {
        setState(() {
          _loading = false;
          _notFound = provider.error == null;
          _loadError = provider.error;
        });
        return;
      }
      _existing = client;
      _nameCtrl.text = client.nomComplet;
      _phoneCtrl.text = client.telephone ?? '';
      _addressCtrl.text = client.adresse ?? '';
      _notesCtrl.text = client.notes ?? '';
    }

    _initialName = _nameCtrl.text;
    _initialPhone = _phoneCtrl.text;
    _initialAddress = _addressCtrl.text;
    _initialNotes = _notesCtrl.text;
    setState(() {
      _loading = false;
      _loadError = provider.error;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonner la saisie ?'),
        content: const Text(
          'Les informations saisies ne seront pas enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuer la saisie'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _handleBack() async {
    if (_isDirty && !await _confirmDiscard()) return;
    if (mounted) context.pop();
  }

  Future<bool> _confirmDuplicate(AtelierClient other) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ce numéro existe déjà'),
        content: Text(
          '« ${other.nomComplet} » utilise déjà ce numéro de téléphone. '
          'Voulez-vous quand même enregistrer ce client ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Modifier le numéro'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enregistrer quand même'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  String? _nullIfEmpty(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final atelier = context.read<AtelierProvider>().atelier;
    if (atelier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atelier introuvable. Réessayez après reconnexion.'),
        ),
      );
      return;
    }

    final clients = context.read<ClientsProvider>();
    final phone = _nullIfEmpty(_phoneCtrl.text);
    if (phone != null) {
      final digits = FormValidators.digitsOnly(phone);
      final duplicate = clients.clients.where((client) {
        final existingPhone = client.telephone;
        return client.id != _existing?.id &&
            existingPhone != null &&
            FormValidators.digitsOnly(existingPhone) == digits;
      }).firstOrNull;
      if (duplicate != null && !await _confirmDuplicate(duplicate)) return;
      if (!mounted) return;
    }

    setState(() => _saving = true);
    final existing = _existing;
    try {
      final operation = existing == null
          ? clients.addClient(
              AtelierClient(
                id: '',
                userId: atelier.userId,
                nomComplet: _nameCtrl.text.trim(),
                telephone: phone,
                adresse: _nullIfEmpty(_addressCtrl.text),
                notes: _nullIfEmpty(_notesCtrl.text),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
          : clients.updateClient(existing.id, {
              'nom_complet': _nameCtrl.text.trim(),
              'telephone': phone,
              'adresse': _nullIfEmpty(_addressCtrl.text),
              'notes': _nullIfEmpty(_notesCtrl.text),
            });
      final result = await saveWithOfflineGrace(
        operation,
        onLocalWrite: SyncStatus.instance.onLocalWrite,
      );
      if (!mounted) return;
      if (!result.ok) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.error!)));
        return;
      }

      _saved = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.pendingSync
                ? 'Client enregistré sur le téléphone. Il sera envoyé dès que '
                    'la connexion reviendra.'
                : (_isEditing
                    ? 'Modifications du client enregistrées.'
                    : 'Client enregistré.'),
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer le client : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _loadError != null && _existing == null && _isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ??
                      'Ce client est introuvable. Il a peut-être été supprimé.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final router = GoRouter.of(context);
    return PopScope(
      canPop: _saved || !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_isDirty) return;
        final discard = await _confirmDiscard();
        if (!mounted) return;
        if (!discard) return;
        router.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier le client' : 'Nouveau client'),
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _ClientFormSectionTitle('Informations essentielles'),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: FormValidators.requiredName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s.]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '90 00 00 00',
                    helperText: 'Facultatif · 8 chiffres sans indicatif',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: FormValidators.nigerPhone,
                ),
                const SizedBox(height: 24),
                const _ClientFormSectionTitle(
                  'Informations complémentaires',
                ),
                TextFormField(
                  controller: _addressCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Adresse ou quartier',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => FormValidators.optionalMax(
                    value,
                    FormValidators.addressMax,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => FormValidators.optionalMax(
                    value,
                    FormValidators.notesMax,
                  ),
                ),
                if (_loadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Vérification des doublons indisponible : $_loadError',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '* Champ obligatoire',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing
                          ? 'Enregistrer les modifications'
                          : 'Enregistrer le client',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientFormSectionTitle extends StatelessWidget {
  const _ClientFormSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
        child: Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
}
