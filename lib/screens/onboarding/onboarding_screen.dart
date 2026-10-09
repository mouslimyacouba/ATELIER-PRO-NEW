import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/type_atelier.dart';
import '../../providers/atelier_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  TypeAtelier? _typeAtelier;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedType = _typeAtelier;
    if (selectedType == null) {
      setState(() => _error = 'Choisissez le métier de votre atelier.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer votre métier'),
        content: Text(
          'Vous avez choisi « ${selectedType.dbValue} ». Ce choix est '
          'définitif et ne pourra plus être modifié pour ce compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Modifier'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await context.read<AtelierProvider>().createAtelier(
          nomAtelier: _nomCtrl.text.trim(),
          specialite: selectedType.dbValue,
          telephone: _telephoneCtrl.text.trim().isEmpty
              ? null
              : _telephoneCtrl.text.trim(),
          ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result;
    });
    // Si result == null, le router redirige automatiquement vers '/'
    // dès que AtelierProvider notifie son changement d'état.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtelierProColors.sable,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Row(
                        children: [
                          const Text(
                            'Étape 2 sur 2',
                            style: TextStyle(
                              fontSize: 13,
                              color: AtelierProColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: const LinearProgressIndicator(
                                value: 1,
                                minHeight: 5,
                                backgroundColor:
                                    AtelierProColors.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  AtelierProColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quel est le métier de votre atelier ?',
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AtelierProColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Choix définitif. Vous ne pourrez plus changer de métier avec ce compte. Pour un autre métier, il faudra créer un nouveau compte.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AtelierProColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final columns = gridConstraints.maxWidth < 340 ? 1 : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: TypeAtelier.values.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: 52,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              final type = TypeAtelier.values[index];
                              return _TypeChoice(
                                label: type.dbValue,
                                selected: type == _typeAtelier,
                                onTap: () =>
                                    setState(() => _typeAtelier = type),
                              );
                            },
                          );
                        },
                      ),
                      if (_typeAtelier == null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Sélection obligatoire avant de continuer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AtelierProColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        "Nom de l'atelier",
                        style: TextStyle(
                          fontSize: 13,
                          color: AtelierProColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nomCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Ex. : Atelier du Centre',
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return "Entrez le nom de l'atelier.";
                          if (name.length > 120) {
                            return 'Le nom doit contenir 120 caractères maximum.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telephoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone (facultatif)',
                          hintText: '90 00 00 00',
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) return null;
                          final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length != 8) {
                            return 'Le numéro doit avoir 8 chiffres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _villeCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Ville (facultatif)',
                        ),
                        validator: (value) {
                          if ((value?.trim().length ?? 0) > 100) {
                            return 'La ville doit contenir 100 caractères maximum.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AtelierProColors.rougeAlerte,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Créer mon atelier'),
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

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AtelierProColors.primaryFixed
                : AtelierProColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AtelierProColors.primary
                  : AtelierProColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: AtelierProColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
