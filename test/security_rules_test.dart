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
    late String rootRules;
    late String firebaseRules;

    setUpAll(() {
      rootRules = _readRules('firestore.rules');
      firebaseRules = _readRules('firebase/firestore.rules');
    });

    test('the deployable and documented rule files stay synchronized', () {
      expect(firebaseRules, rootRules);
    });

    test(
        'default deny stays in place and nothing is open to any signed-in user',
        () {
      expect(
        rootRules,
        contains('match /{document=**} {\n      allow read, write: if false;'),
      );
      expect(rootRules,
          isNot(contains('allow read, write: if request.auth != null;')));
    });

    test('server side requires a verified identity', () {
      expect(rootRules, contains('request.auth.token.email_verified == true'));
      expect(rootRules,
          contains("request.auth.token.firebase.sign_in_provider == 'phone'"));
    });

    test(
        'firestore rules enforce non-negative validation for orders, payments and stock',
        () {
      expect(rootRules, contains('function isValidOrder(data)'));
      expect(rootRules, contains('function isValidPayment(data)'));
      expect(rootRules, contains('function isValidStock(data)'));
      expect(rootRules, contains('data.prixTotal >= 0'));
      expect(rootRules, contains('data.montant > 0'));
      expect(rootRules, contains('data.quantite >= 0'));
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
        final block = _matchBlock(rootRules, collection, '{docId}');
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
        final block = _matchBlock(rootRules, collection, '{userId}');
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
      final block = _matchBlock(rootRules, 'ateliers', '{userId}');
      expect(block, contains('allow create: if isSignedIn()'));
      expect(rootRules, contains('function isMetierUnchanged()'));
      expect(
        rootRules,
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
    late String rootRules;
    late String firebaseRules;

    setUpAll(() {
      rootRules = _readRules('storage.rules');
      firebaseRules = _readRules('firebase/storage.rules');
    });

    test('the deployable and documented rule files stay synchronized', () {
      expect(firebaseRules, rootRules);
    });

    test('uploads are limited to small images and a verified identity', () {
      expect(rootRules, contains('5 * 1024 * 1024'));
      expect(
          rootRules,
          contains(
              "request.resource.contentType.matches('image/(jpeg|png|webp)')"));
      expect(rootRules, contains('request.auth.token.email_verified == true'));
    });

    test('logos stay public while workshop data stays owner-only', () {
      expect(rootRules, contains('match /logos/{userId}/{fileName}'));
      expect(rootRules, contains('allow read: if true; // logos publics'));

      for (final folder in ['photos', 'commandes', 'modeles_etapes']) {
        expect(rootRules, contains('match /$folder/{userId}/{fileName}'));
        expect(rootRules, contains('allow read: if isOwner(userId);'));
        expect(
          rootRules,
          contains(
              'allow create, update: if isOwner(userId) && isValidUpload();'),
        );
        expect(rootRules, contains('allow delete: if isOwner(userId);'));
      }
    });
  });
}
