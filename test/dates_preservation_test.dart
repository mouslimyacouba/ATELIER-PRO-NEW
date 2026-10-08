import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/models/payment.dart';
import 'package:atelierpro_mobile/models/fiche_mesure.dart';

void main() {
  group('Date Preservation Tests', () {
    test('AtelierPayment preserves original datePaiement and createdAt in toInsertMap', () {
      final pastDate = DateTime(2025, 5, 10, 14, 30);
      final payment = AtelierPayment(
        id: 'p1',
        userId: 'u1',
        commandeId: 'c1',
        clientId: 'cli1',
        montant: 15000,
        mode: 'especes',
        datePaiement: pastDate,
        createdAt: pastDate,
      );

      final map = payment.toInsertMap();
      final datePaiementTs = map['datePaiement'] as Timestamp;
      final createdAtTs = map['createdAt'] as Timestamp;

      expect(datePaiementTs.toDate(), equals(pastDate));
      expect(createdAtTs.toDate(), equals(pastDate));
    });

    test('FicheMesure preserves original createdAt in toInsertMap', () {
      final pastDate = DateTime(2025, 1, 15, 10, 00);
      final fiche = FicheMesure(
        id: 'f1',
        userId: 'u1',
        clientId: 'cli1',
        titre: 'Mesures Robe',
        mesures: {'epaule': 40},
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      final map = fiche.toInsertMap();
      final createdAtTs = map['createdAt'] as Timestamp;

      expect(createdAtTs.toDate(), equals(pastDate));
    });
  });
}
