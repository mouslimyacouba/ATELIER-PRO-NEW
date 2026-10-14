import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/metier_config.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// DynamicFieldWidget - Composant de saisie dynamique adapté au Design System Sahara Craft Tech.
///
/// Prend en charge les différents types de champs métiers (nombre, texte, sélection,
/// date, multiline, booléen) ainsi qu'un sélecteur d'unités de mesure (cm / in / mm).
class DynamicFieldWidget extends StatefulWidget {
  final ChampMetier field;
  final TextEditingController controller;
  final String? initialUnit;
  final ValueChanged<String>? onUnitChanged;

  const DynamicFieldWidget({
    super.key,
    required this.field,
    required this.controller,
    this.initialUnit,
    this.onUnitChanged,
  });

  @override
  State<DynamicFieldWidget> createState() => _DynamicFieldWidgetState();
}

class _DynamicFieldWidgetState extends State<DynamicFieldWidget> {
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit ?? 'cm';
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.field.type) {
      case TypeChampMetier.number:
        return _buildNumberField(context);

      case TypeChampMetier.select:
        return _buildSelectField(context);

      case TypeChampMetier.multiline:
        return _buildMultilineField(context);

      case TypeChampMetier.date:
        return _DateFieldWidget(field: widget.field, controller: widget.controller);

      case TypeChampMetier.boolean:
        return _BoolFieldWidget(field: widget.field, controller: widget.controller);

      case TypeChampMetier.text:
        return _buildTextField(context);
    }
  }

  Widget _buildNumberField(BuildContext context) {
    // Si le champ concerne une mesure (contient "mesure", "longueur", "largeur", "hauteur", "taille", "diametre"), on affiche le sélecteur d'unités cm / in / mm.
    final isMeasurement = widget.field.key.contains('mesure') ||
        widget.field.label.toLowerCase().contains('mesure') ||
        widget.field.label.toLowerCase().contains('longueur') ||
        widget.field.label.toLowerCase().contains('largeur') ||
        widget.field.label.toLowerCase().contains('taille') ||
        widget.field.label.toLowerCase().contains('hauteur');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.field.label,
            hintText: '0.0',
            suffixIcon: isMeasurement
                ? Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _UnitSwitcherPill(
                      selectedUnit: _selectedUnit,
                      onChanged: (unit) {
                        setState(() {
                          _selectedUnit = unit;
                        });
                        if (widget.onUnitChanged != null) {
                          widget.onUnitChanged!(unit);
                        }
                      },
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          validator: widget.field.obligatoire
              ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildSelectField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: widget.controller.text.isEmpty ? null : widget.controller.text,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary),
      style: TextStyle(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        color: colors.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: 'Sélectionner une option',
      ),
      items: widget.field.options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o),
              ))
          .toList(),
      onChanged: (v) => widget.controller.text = v ?? '',
      validator: widget.field.obligatoire
          ? (v) => (v == null || v.isEmpty) ? 'Sélection requise' : null
          : null,
    );
  }

  Widget _buildMultilineField(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      maxLines: 3,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: 'Saisissez les précisions ou remarques...',
        alignLabelWithHint: true,
      ),
      validator: widget.field.obligatoire
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: widget.field.label,
      ),
      validator: widget.field.obligatoire
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}

/// Sélecteur d'unités tactile en pilule (cm / in / mm)
class _UnitSwitcherPill extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onChanged;

  const _UnitSwitcherPill({
    required this.selectedUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final units = ['cm', 'in', 'mm'];
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.map((unit) {
          final isSelected = selectedUnit == unit;
          return GestureDetector(
            onTap: () => onChanged(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateFieldWidget extends StatelessWidget {
  final ChampMetier field;
  final TextEditingController controller;
  const _DateFieldWidget({required this.field, required this.controller});

  Future<void> _pickDate(BuildContext context) async {
    DateTime initial;
    try {
      initial = controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : DateTime.now();
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        String display = '';
        if (value.text.isNotEmpty) {
          try {
            display = _dateFormat.format(DateTime.parse(value.text));
          } catch (_) {
            display = value.text;
          }
        }
        return FormField<String>(
          validator: field.obligatoire
              ? (_) => value.text.isEmpty ? 'Date requise' : null
              : null,
          builder: (state) => InputDecorator(
            decoration: InputDecoration(
              labelText: field.label,
              errorText: state.errorText,
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today_rounded,
                    size: 20, color: colors.primary),
                onPressed: () => _pickDate(context),
              ),
            ),
            child: InkWell(
              onTap: () => _pickDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  display.isEmpty ? 'JJ/MM/AAAA' : display,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: display.isEmpty ? FontWeight.w400 : FontWeight.w600,
                    color: display.isEmpty ? colors.onSurfaceVariant : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoolFieldWidget extends StatelessWidget {
  final ChampMetier field;
  final TextEditingController controller;
  const _BoolFieldWidget({required this.field, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final isTrue = value.text == 'true';
        final isFalse = value.text == 'false';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
              child: Text(
                field.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isTrue ? colors.primary : colors.surface,
                      foregroundColor: isTrue ? colors.onPrimary : colors.onSurface,
                      side: BorderSide(
                        color: isTrue ? colors.primary : colors.outlineVariant,
                        width: 1,
                      ),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => controller.text = 'true',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isTrue)
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: colors.onPrimary),
                        if (isTrue) const SizedBox(width: 6),
                        const Text('Oui', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isFalse
                          ? colors.surfaceContainerHighest
                          : colors.surface,
                      foregroundColor: colors.onSurface,
                      side: BorderSide(
                        color: isFalse ? colors.primary : colors.outlineVariant,
                        width: 1,
                      ),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => controller.text = 'false',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isFalse)
                          Icon(Icons.cancel_rounded,
                              size: 16, color: colors.onSurfaceVariant),
                        if (isFalse) const SizedBox(width: 6),
                        const Text('Non', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
