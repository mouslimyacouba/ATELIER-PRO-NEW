/// Shared validation for client and measurement forms.
class FormValidators {
  const FormValidators._();

  static const int nameMax = 120;
  static const int addressMax = 300;
  static const int notesMax = 5000;
  static const int titleMax = 150;

  static String? requiredName(String? value, {String label = 'Le nom'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label est obligatoire.';
    if (text.length > nameMax) return 'Maximum $nameMax caractères.';
    return null;
  }

  static String? nigerPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (digitsOnly(text).length != 8) {
      return 'Le numéro doit avoir 8 chiffres.';
    }
    return null;
  }

  static String? optionalMax(String? value, int max) {
    if ((value?.trim().length ?? 0) > max) return 'Maximum $max caractères.';
    return null;
  }

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static double? parseMeasure(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  static String? measure(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Ce champ est obligatoire.' : null;
    final number = parseMeasure(text);
    if (number == null || number <= 0 || number > 100000) {
      return 'Entrez un nombre valide.';
    }
    return null;
  }

  static String? requiredText(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Ce champ est obligatoire.' : null;
}
