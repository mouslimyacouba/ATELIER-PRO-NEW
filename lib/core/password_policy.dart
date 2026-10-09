/// Politique de mot de passe d'AtelierPro, appliquée à l'inscription.
///
/// Elle ne s'applique volontairement PAS à la connexion : d'anciens comptes
/// ont pu être créés avec 6 caractères et doivent pouvoir se connecter.
enum PasswordStrength { empty, weak, medium, strong }

class PasswordPolicy {
  const PasswordPolicy._();

  static const int minLength = 8;
  static const int maxLength = 128;

  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasUpper = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _hasLower = RegExp(r'\p{Ll}', unicode: true);
  static final RegExp _hasSymbol =
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static const Set<String> _common = {
    '12345678',
    '123456789',
    '1234567890',
    '87654321',
    '11111111',
    '00000000',
    'password',
    'password1',
    'password123',
    'motdepasse',
    'motdepasse1',
    'azerty123',
    'azertyui',
    'azertyuiop',
    'qwerty123',
    'qwertyuiop',
    'abcd1234',
    'atelierpro',
    'atelierpro1',
    'atelierpro123',
  };

  /// Renvoie un message d'erreur en français, ou `null` si le mot de passe
  /// respecte la politique : 8 à 128 caractères, au moins une lettre et un
  /// chiffre, ni trop courant, ni construit sur la partie locale de l'e-mail.
  static String? validate(String password, {String? email}) {
    if (password.length < minLength) {
      return 'Minimum $minLength caractères.';
    }
    if (password.length > maxLength) {
      return 'Maximum $maxLength caractères.';
    }
    if (!_hasLetter.hasMatch(password)) {
      return 'Ajoutez au moins une lettre.';
    }
    if (!_hasDigit.hasMatch(password)) {
      return 'Ajoutez au moins un chiffre.';
    }
    if (_isTooCommon(password)) {
      return 'Ce mot de passe est trop courant. Choisissez-en un autre.';
    }
    if (_containsEmailName(password, email)) {
      return 'Le mot de passe ne doit pas contenir votre adresse e-mail.';
    }
    return null;
  }

  /// Solidité affichée à l'utilisateur.
  /// - faible : ne respecte pas la politique (refusé) ;
  /// - moyenne : respecte la politique ;
  /// - forte : respecte la politique et cumule au moins deux atouts parmi
  ///   12 caractères ou plus, majuscules et minuscules, symbole.
  static PasswordStrength strength(String password, {String? email}) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (validate(password, email: email) != null) {
      return PasswordStrength.weak;
    }
    var bonus = 0;
    if (password.length >= 12) bonus++;
    if (_hasUpper.hasMatch(password) && _hasLower.hasMatch(password)) bonus++;
    if (_hasSymbol.hasMatch(password)) bonus++;
    return bonus >= 2 ? PasswordStrength.strong : PasswordStrength.medium;
  }

  /// Prochain conseil pour renforcer le mot de passe (`null` si rien à dire).
  static String? suggestion(String password, {String? email}) {
    if (password.isEmpty) return null;
    final error = validate(password, email: email);
    if (error != null) return error;
    if (strength(password, email: email) == PasswordStrength.strong) {
      return null;
    }
    if (password.length < 12) {
      return 'Allongez-le (12 caractères ou plus) pour le renforcer.';
    }
    if (!(_hasUpper.hasMatch(password) && _hasLower.hasMatch(password))) {
      return 'Mélangez majuscules et minuscules.';
    }
    return 'Ajoutez un symbole (par exemple ! ou -).';
  }

  static bool _isTooCommon(String password) {
    final lower = password.toLowerCase();
    if (_common.contains(lower)) return true;
    // Un seul caractère répété (« 11111111 », « aaaaaaaa »).
    return lower.runes.toSet().length == 1;
  }

  static bool _containsEmailName(String password, String? email) {
    if (email == null || !email.contains('@')) return false;
    final local = email.split('@').first.trim().toLowerCase();
    return local.length >= 4 && password.toLowerCase().contains(local);
  }
}
