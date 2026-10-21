import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _ownerUid = 'atelier-owner';
const _otherUid = 'other-workshop';

bool _isOwner(String authUid, String documentOwnerUid) =>
    authUid == documentOwnerUid;

String _readRules(String path) => File(path).readAsStringSync();

/// Extrait le bloc `match /<collection>/<param> { ... }` d'un fichier de
/// règles (accolades équilibrées) pour tester chaque collection séparément.
String _matchBlock(String rules, String collection, String param) {
  final header = 'match /$collection/$param {';
  final start = rules.indexOf(header);
  expect(start, greaterThanOrEqualTo(0),
      reason: 'bloc $collection introuvable');
  var depth = 0;
  for (var i = start + header.length - 1; i < rules.length; i++) {
    if (rules[i] == '{') depth++;
    if (rules[i] == '}') {
      depth--;
      if (depth == 0) return rules.substring(start, i + 1);
    }
  }
  fail('bloc $collection non fermé');
}

void main() {
  group('Firestore security rules contract', () {
    late String rules;

    setUpAll(() {
      rules = _readRules('firebase/firestore.rules');
    });

    test(
        'default deny stays in place and nothing is open to any signed-in user',
        () {
      expect(
        rules,
        contains('match /{document=**} {\n      allow read, write: if false;'),
      );
      expect(rules,
          isNot(contains('allow read, write: if request.auth != null;')));
    });

    test('server side requires a verified identity', () {
      expect(rules, contains('request.auth.token.email_verified == true'));
      expect(rules,
          contains("request.auth.token.firebase.sign_in_provider == 'phone'"));
    });

    test(
        'firestore rules enforce non-negative validation for orders, payments and stock',
        () {
      expect(rules, contains('function isValidOrder(data)'));
      expect(rules, contains('function isValidPayment(data)'));
      expect(rules, contains('function isValidStock(data)'));
      expect(rules, contains('data.prixTotal >= 0'));
      expect(rules, contains('data.montant > 0'));
      expect(rules, contains('data.quantite >= 0'));
    });

    test('every user-owned collection has owner checks and a validator', () {
      const validators = {
        'clients': 'isValidClient',
        'commandes': 'isValidOrder',
        'paiements': 'isValidPayment',
        'fiches': 'isValidFiche',
        'modeles': 'isValidModele',
        'stock': 'isValidStock',
        'historique_modifications': 'isValidHistorique',
      };
      validators.forEach((collection, validator) {
        final block = _matchBlock(rules, collection, '{docId}');
        expect(
            block, contains('allow read, delete: if isOwner(resource.data);'),
            reason: collection);
        expect(
            block, contains('allow create: if isOwner(request.resource.data)'),
            reason: collection);
        expect(block, contains('$validator(request.resource.data)'),
            reason: collection);
        if (collection == 'historique_modifications') {
          // Journal d'audit : jamais de mise à jour.
          expect(block, isNot(contains('allow update')), reason: collection);
        } else {
          expect(
            block,
            contains('allow update: if isOwner(resource.data) && '
                'isOwner(request.resource.data)'),
            reason: collection,
          );
        }
      });
    });

    test('per-user documents validate writes but still allow deletion', () {
      const validators = {
        'ateliers': 'isValidAtelier',
        'compteurs': 'isValidCompteur',
      };
      validators.forEach((collection, validator) {
        final block = _matchBlock(rules, collection, '{userId}');
        expect(
            block,
            contains('allow read, delete: if isSignedIn() && '
                'request.auth.uid == userId;'),
            reason: collection);
        if (collection == 'ateliers') {
          expect(block, contains('allow create:'), reason: collection);
          expect(block, contains('allow update:'), reason: collection);
        } else {
          expect(block, contains('allow create, update:'), reason: collection);
        }
        expect(block, contains('$validator(request.resource.data)'),
            reason: collection);
        // `write` mélangerait suppression et validation : request.resource
        // est nul à la suppression.
        expect(block, isNot(contains('allow read, write')), reason: collection);
      });
    });

    test('atelier métier can be set on creation but not changed later', () {
      final block = _matchBlock(rules, 'ateliers', '{userId}');
      expect(block, contains('allow create: if isSignedIn()'));
      expect(rules, contains('function isMetierUnchanged()'));
      expect(
        rules,
        contains(
          "resource.data.get('specialite', null) == null\n"
          "        || request.resource.data.get('specialite', null) == resource.data.specialite;",
        ),
      );
      expect(block, contains('allow update: if isSignedIn()'));
      expect(block, contains('&& isMetierUnchanged();'));
    });

    test('owner and non-owner access cases are explicit', () {
      expect(_isOwner(_ownerUid, _ownerUid), isTrue);
      expect(_isOwner(_otherUid, _ownerUid), isFalse);
      expect(_isOwner('', _ownerUid), isFalse);
    });
  });

  group('Storage security rules contract', () {
    late String rules;

    setUpAll(() {
      rules = _readRules('firebase/storage.rules');
    });

    test('uploads are limited to small images and a verified identity', () {
      expect(rules, contains('5 * 1024 * 1024'));
      expect(
          rules,
          contains(
              "request.resource.contentType.matches('image/(jpeg|png|webp)')"));
      expect(rules, contains('request.auth.token.email_verified == true'));
    });

    test('logos stay public while workshop data stays owner-only', () {
      expect(rules, contains('match /logos/{userId}/{fileName}'));
      expect(rules, contains('allow read: if true; // logos publics'));

      for (final folder in ['photos', 'commandes', 'modeles_etapes']) {
        expect(rules, contains('match /$folder/{userId}/{fileName}'));
        expect(rules, contains('allow read: if isOwner(userId);'));
        expect(
          rules,
          contains(
              'allow create, update: if isOwner(userId) && isValidUpload();'),
        );
        expect(rules, contains('allow delete: if isOwner(userId);'));
      }
    });
  });
}
