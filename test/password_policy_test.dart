import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/core/password_policy.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('refuse un mot de passe trop court', () {
      expect(PasswordPolicy.validate('abc12'), isNotNull);
      expect(PasswordPolicy.validate('abcd123'), isNotNull); // 7 caractères
    });

    test('exige au moins une lettre et un chiffre', () {
      expect(PasswordPolicy.validate('abcdefgh'), contains('chiffre'));
      expect(PasswordPolicy.validate('48201593'), contains('lettre'));
    });

    test('accepte un mot de passe conforme', () {
      expect(PasswordPolicy.validate('atelier2026'), isNull);
      expect(PasswordPolicy.validate('Zinder-Couture-42'), isNull);
    });

    test('refuse les mots de passe courants, quelle que soit la casse', () {
      expect(PasswordPolicy.validate('Password1'), contains('courant'));
      expect(PasswordPolicy.validate('12345678'), isNotNull);
      expect(PasswordPolicy.validate('AtelierPro123'), contains('courant'));
    });

    test('refuse un caractère unique répété', () {
      expect(PasswordPolicy.validate('11111111'), isNotNull);
    });

    test("refuse un mot de passe construit sur l'adresse e-mail", () {
      expect(
        PasswordPolicy.validate('moussa2026x', email: 'moussa@exemple.com'),
        contains('e-mail'),
      );
      // Partie locale trop courte : pas de rejet.
      expect(
        PasswordPolicy.validate('abcd2026x', email: 'ab@exemple.com'),
        isNull,
      );
    });

    test('refuse plus de 128 caractères', () {
      expect(PasswordPolicy.validate('a1' * 65), contains('Maximum'));
    });

    test('accepte les lettres accentuées', () {
      expect(PasswordPolicy.validate('éléphant42'), isNull);
    });
  });

  group('PasswordPolicy.strength', () {
    test('vide, faible, moyenne, forte', () {
      expect(PasswordPolicy.strength(''), PasswordStrength.empty);
      expect(PasswordPolicy.strength('abc'), PasswordStrength.weak);
      expect(PasswordPolicy.strength('atelier2026'), PasswordStrength.medium);
      expect(PasswordPolicy.strength('Atelier2026!'), PasswordStrength.strong);
    });

    test('un mot de passe refusé est toujours faible', () {
      expect(PasswordPolicy.strength('password1'), PasswordStrength.weak);
    });
  });

  group('PasswordPolicy.suggestion', () {
    test('aucun conseil pour un mot de passe fort ou vide', () {
      expect(PasswordPolicy.suggestion(''), isNull);
      expect(PasswordPolicy.suggestion('Atelier2026!'), isNull);
    });

    test('propose une amélioration pour un mot de passe moyen', () {
      expect(PasswordPolicy.suggestion('atelier2026'), contains('Allongez'));
    });
  });
}
