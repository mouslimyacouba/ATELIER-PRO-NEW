import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atelierpro_mobile/core/client_deletion_policy.dart';
import 'package:atelierpro_mobile/core/firestore_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('client deletion policy', () {
    test('blocks deletion when the client has a command', () {
      expect(
        clientDeletionBlockMessage(orderCount: 1, paymentCount: 0),
        contains('commandes'),
      );
    });

    test('preserves orphaned payment history instead of deleting it', () {
      expect(
        clientDeletionBlockMessage(orderCount: 0, paymentCount: 1),
        contains('paiements'),
      );
    });

    test('allows deleting a client without financial history', () {
      expect(
        clientDeletionBlockMessage(orderCount: 0, paymentCount: 0),
        isNull,
      );
    });

    test('converts Firestore deletion failures to an actionable message', () {
      final message = friendlyFirestoreError(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      expect(message, contains('Accès refusé'));
      expect(message, isNot(contains('permission-denied')));
    });
  });
}
