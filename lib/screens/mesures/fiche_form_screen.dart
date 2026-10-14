import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/fiche_templates.dart';
import '../../core/form_validators.dart';
import '../../core/offline_save.dart';
import '../../core/sync_status.dart';
import '../../models/champ_fiche.dart';
import '../../models/fiche_mesure.dart';
import '../../models/fiche_template.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/fiches_mesures_provider.dart';

class FicheFormScreen extends StatefulWidget {
  const FicheFormScreen({super.key, this.ficheId, this.initialClientId});

  final String? ficheId;
  final String? initialClientId;

  @override
  State<FicheFormScreen> createState() => _FicheFormScreenState();
}

class _FicheFormScreenState extends State<FicheFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _champCtrls = <String, TextEditingController>{};
  final _champListe = <String, String?>{};

  late FicheTemplate _template;
  FicheMesure? _existing;
  String? _clientId;
  bool _initialized = false;
  bool _loading = true;
  bool _notFound = false;
  bool _editing = false;
  bool _saving = false;
  bool _saved = false;
  String? _loadError;
  String _initialSignature = '';

  bool get _isNew => widget.ficheId == null;
  bool get _isDirty => _editing && _signature != _initialSignature;

  String get _signature => [
        _clientId ?? '',
        _titleCtrl.text,
        _notesCtrl.text,
        for (final champ in _template.champs)
          champ.typeChamp == TypeChamp.liste
              ? (_champListe[champ.id] ?? '')
              : (_champCtrls[champ.id]?.text ?? ''),
      ].join('\u0001');

  static String _displayValue(Object? value) {
    if (value == null) return '';
    if (value is num && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final atelier = context.read<AtelierProvider>().atelier;
    _template =
        ficheTemplates[atelier?.typeAtelier] ?? ficheTemplates.values.last;
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

    final clientsProvider = context.read<ClientsProvider>();
    final fichesProvider = context.read<FichesMesuresProvider>();
    await Future.wait([
      clientsProvider.load(atelier.userId),
      fichesProvider.load(atelier.userId),
    ]);
    if (!mounted) return;

    final id = widget.ficheId;
    if (id != null) {
      _existing = fichesProvider.byId(id);
      if (_existing == null) {
        setState(() {
          _loading = false;
          _notFound = fichesProvider.error == null;
          _loadError = fichesProvider.error;
        });
        return;
      }
    }

    final clients = clientsProvider.clients;
    final existing = _existing;
    final requestedId = widget.initialClientId;
    _titleCtrl.text = existing?.titre ?? _template.nomFiche;
    _notesCtrl.text = existing?.notes ?? '';
    _clientId = existing?.clientId ??
        (clients.any((client) => client.id == requestedId)
            ? requestedId
            : (clients.length == 1 ? clients.first.id : null));

    for (final champ in _template.champs) {
      final value = existing?.mesures[champ.id];
      if (champ.typeChamp == TypeChamp.liste) {
        _champListe[champ.id] = value?.toString();
      } else {
        _champCtrls[champ.id] =
            TextEditingController(text: _displayValue(value));
      }
    }

    _editing = _isNew;
    _initialSignature = _signature;
    setState(() {
      _loading = false;
      _loadError = clientsProvider.error ?? fichesProvider.error;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    for (final controller in _champCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonner les modifications ?'),
        content: const Text('Ce que vous avez saisi ne sera pas enregistré.'),
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

  Future<void> _addClient() async {
    await context.push('/clients/nouveau');
    if (!mounted) return;
    final atelier = context.read<AtelierProvider>().atelier;
    if (atelier != null) {
      await context.read<ClientsProvider>().load(atelier.userId);
    }
    if (!mounted) return;
    final clients = context.read<ClientsProvider>().clients;
    if (_clientId == null && clients.length == 1) {
      setState(() => _clientId = clients.first.id);
    } else {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final atelier = context.read<AtelierProvider>().atelier;
    final clientId = _clientId;
    if (atelier == null || clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un client avant d’enregistrer.'),
        ),
      );
      return;
    }

    final data = Map<String, dynamic>.from(_existing?.mesures ?? const {});
    for (final champ in _template.champs) {
      if (champ.typeChamp == TypeChamp.liste) {
        final value = _champListe[champ.id];
        if (value == null || value.isEmpty) {
          data.remove(champ.id);
        } else {
          data[champ.id] = value;
        }
        continue;
      }

      final raw = _champCtrls[champ.id]!.text.trim();
      if (raw.isEmpty) {
        data.remove(champ.id);
      } else if (champ.typeChamp == TypeChamp.nombre) {
        data[champ.id] = FormValidators.parseMeasure(raw) ?? raw;
      } else {
        data[champ.id] = raw;
      }
    }

    final title = _titleCtrl.text.trim();
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    final provider = context.read<FichesMesuresProvider>();
    setState(() => _saving = true);

    try {
      final existing = _existing;
      final operation = existing == null
          ? provider.addFiche(
              FicheMesure(
                id: '',
                userId: atelier.userId,
                clientId: clientId,
                titre: title,
                mesures: data,
                notes: notes,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
          : provider.updateFiche(existing.id, {
              'titre': title,
              'mesures': data,
              'notes': notes,
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
                ? 'Fiche enregistrée sur le téléphone. Elle sera envoyée dès '
                    'que la connexion reviendra.'
                : 'Fiche enregistrée.',
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer la fiche : $error')),
      );
    }
  }

  String get _screenTitle {
    if (_isNew) return 'Nouvelle ${_template.nomFiche.toLowerCase()}';
    return _editing ? 'Modifier la fiche' : _template.nomFiche;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _loadError != null && _existing == null && !_isNew) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ??
                      'Cette fiche est introuvable. Elle a peut-être été supprimée.',
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

    final clients = context.watch<ClientsProvider>().clients;
    final hasNoClient = clients.isEmpty && _isNew;
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
          title: Text(_screenTitle),
          actions: [
            if (!_isNew && !_editing)
              IconButton(
                tooltip: 'Modifier la fiche',
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: SafeArea(
          child: hasNoClient
              ? _NoClientState(onAddClient: _addClient)
              : Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_loadError != null) ...[
                        Text(
                          'Certaines données n’ont pas pu être actualisées : '
                          '$_loadError',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const _FicheSectionTitle('Client et titre'),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_clientId),
                        initialValue:
                            clients.any((client) => client.id == _clientId)
                                ? _clientId
                                : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Client *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: [
                          for (final client in clients)
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(
                                client.nomComplet,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _isNew && _editing
                            ? (value) => setState(() => _clientId = value)
                            : null,
                        validator: (value) =>
                            value == null ? 'Choisissez un client.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleCtrl,
                        readOnly: !_editing,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Le titre est obligatoire.';
                          return FormValidators.optionalMax(
                            text,
                            FormValidators.titleMax,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _FicheSectionTitle(_template.nomFiche),
                      for (final champ in _template.champs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildChamp(champ),
                        ),
                      const _FicheSectionTitle('Notes'),
                      TextFormField(
                        controller: _notesCtrl,
                        readOnly: !_editing,
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
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: hasNoClient
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _editing
                      ? ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enregistrer la fiche'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier la fiche'),
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildChamp(ChampFiche champ) {
    final label = champ.obligatoire ? '${champ.label} *' : champ.label;
    if (champ.typeChamp == TypeChamp.liste) {
      final options = champ.options ?? const <String>[];
      final current = _champListe[champ.id];
      return DropdownButtonFormField<String>(
        key: ValueKey(current),
        initialValue: options.contains(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: _editing
            ? (value) => setState(() => _champListe[champ.id] = value)
            : null,
        validator: champ.obligatoire
            ? (value) => value == null || value.isEmpty
                ? 'Ce champ est obligatoire.'
                : null
            : null,
      );
    }

    final isNumber = champ.typeChamp == TypeChamp.nombre;
    return TextFormField(
      controller: _champCtrls[champ.id],
      readOnly: !_editing,
      textInputAction: TextInputAction.next,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      decoration: InputDecoration(labelText: label, suffixText: champ.unite),
      validator: isNumber
          ? (value) =>
              FormValidators.measure(value, required: champ.obligatoire)
          : (champ.obligatoire ? FormValidators.requiredText : null),
    );
  }
}

class _NoClientState extends StatelessWidget {
  const _NoClientState({required this.onAddClient});

  final VoidCallback onAddClient;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1_outlined, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Ajoutez un client avant de créer sa fiche.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddClient,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Ajouter un client'),
              ),
            ],
          ),
        ),
      );
}

class _FicheSectionTitle extends StatelessWidget {
  const _FicheSectionTitle(this.title);

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
