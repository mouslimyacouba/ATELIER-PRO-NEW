import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/models/order.dart';

void main() {
  group('AtelierOrder Model Tests', () {
    test('AtelierOrder round-trip serialization retains costs and fields', () {
      final now = DateTime.now();
      final order = AtelierOrder(
        id: 'order_123',
        userId: 'user_456',
        clientId: 'client_789',
        clientName: 'Moussa Keita',
        description: 'Boubou traditionnel 3 pièces',
        status: OrderStatus.enCours,
        dateCommande: now,
        dateEcheance: now.add(const Duration(days: 7)),
        prixTotal: 75000.0,
        acompte: 30000.0,
        createdAt: now,
        numero: 12,
        coutMateriaux: 25000.0,
        coutMainDoeuvre: 15000.0,
        coutTransport: 5000.0,
      );

      final insertMap = order.toInsertMap();

      expect(insertMap['coutMateriaux'], equals(25000.0));
      expect(insertMap['coutMainDoeuvre'], equals(15000.0));
      expect(insertMap['coutTransport'], equals(5000.0));

      // Simulate map retrieved from Firestore (where Timestamps replace DateTimes)
      final simulatedFirestoreMap = <String, dynamic>{
        'userId': insertMap['userId'],
        'clientId': insertMap['clientId'],
        'clientNom': insertMap['clientNom'],
        'ficheId': insertMap['ficheId'],
        'description': insertMap['description'],
        'statut': insertMap['statut'],
        'dateCommande': insertMap['dateCommande'],
        'dateEcheance': insertMap['dateEcheance'],
        'prixTotal': insertMap['prixTotal'],
        'acompte': insertMap['acompte'],
        'createdAt': insertMap['createdAt'],
        'modeleId': insertMap['modeleId'],
        'etapesSnapshot': insertMap['etapesSnapshot'],
        'photoUrls': insertMap['photoUrls'],
        'specificationsMetier': insertMap['specificationsMetier'],
        'numero': insertMap['numero'],
        'coutMateriaux': insertMap['coutMateriaux'],
        'coutMainDoeuvre': insertMap['coutMainDoeuvre'],
        'coutTransport': insertMap['coutTransport'],
      };

      final restoredOrder = AtelierOrder.fromMap('order_123', simulatedFirestoreMap);

      expect(restoredOrder.id, equals('order_123'));
      expect(restoredOrder.prixTotal, equals(75000.0));
      expect(restoredOrder.acompte, equals(30000.0));
      expect(restoredOrder.remaining, equals(45000.0));
      expect(restoredOrder.coutMateriaux, equals(25000.0));
      expect(restoredOrder.coutMainDoeuvre, equals(15000.0));
      expect(restoredOrder.coutTransport, equals(5000.0));
      expect(restoredOrder.coutTotalRevient, equals(45000.0));
      expect(restoredOrder.beneficeEstime, equals(30000.0));
      expect(restoredOrder.numeroFormate, equals('CMD-0012'));
    });

    test('AtelierOrder deserialization handles legacy map without cost fields', () {
      final legacyMap = <String, dynamic>{
        'userId': 'user_1',
        'clientId': 'client_1',
        'description': 'Commande ancienne',
        'statut': 'en_attente',
        'dateCommande': Timestamp.now(),
        'prixTotal': 20000.0,
        'acompte': 5000.0,
        'createdAt': Timestamp.now(),
      };

      final order = AtelierOrder.fromMap('legacy_1', legacyMap);

      expect(order.coutMateriaux, equals(0.0));
      expect(order.coutMainDoeuvre, equals(0.0));
      expect(order.coutTransport, equals(0.0));
      expect(order.coutTotalRevient, equals(0.0));
      expect(order.beneficeEstime, equals(20000.0));
      expect(order.remaining, equals(15000.0));
    });
  });
}
