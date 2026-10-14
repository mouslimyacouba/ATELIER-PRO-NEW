import 'package:atelierpro_mobile/models/atelier.dart';
import 'package:atelierpro_mobile/models/client.dart';
import 'package:atelierpro_mobile/models/fiche_mesure.dart';
import 'package:atelierpro_mobile/providers/atelier_provider.dart';
import 'package:atelierpro_mobile/providers/clients_provider.dart';
import 'package:atelierpro_mobile/providers/fiches_mesures_provider.dart';
import 'package:flutter/material.dart';

class FakeAtelierProvider extends ChangeNotifier implements AtelierProvider {
  FakeAtelierProvider(this.atelier);

  @override
  Atelier? atelier;
  String? createdName;
  String? createdSpecialite;

  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  Future<String?> createAtelier({
    required String nomAtelier,
    String? specialite,
    String? telephone,
    String? ville,
  }) async {
    createdName = nomAtelier;
    createdSpecialite = specialite;
    return null;
  }

  @override
  Future<String?> updateAtelier(Map<String, dynamic> changes) async => null;

  @override
  Future<String?> updateLogo(String logoUrl) async => null;

  @override
  Future<String?> deleteAtelier() async => null;

  @override
  void reset() {}
}

class FakeClientsProvider extends ChangeNotifier implements ClientsProvider {
  FakeClientsProvider({List<AtelierClient> initialClients = const []})
      : clients = initialClients;

  @override
  List<AtelierClient> clients;

  @override
  bool get loading => false;

  @override
  String? get error => null;

  int addCalls = 0;
  String? updateId;
  Map<String, dynamic>? updateChanges;
  Future<String?> Function(AtelierClient client)? onAdd;
  Future<String?> Function(String id, Map<String, dynamic> changes)? onUpdate;

  @override
  Future<void> load(String userId, {bool forceRefresh = false}) async {}

  @override
  Future<String?> addClient(AtelierClient client) async {
    addCalls++;
    return onAdd?.call(client);
  }

  @override
  Future<String?> updateClient(String id, Map<String, dynamic> changes) async {
    updateId = id;
    updateChanges = changes;
    return onUpdate?.call(id, changes);
  }

  @override
  Future<String?> updatePhoto(String clientId, String photoUrl) async => null;

  @override
  Future<String?> deleteClient(String id, String userId) async => null;

  @override
  AtelierClient? byId(String id) {
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }
}

class FakeFichesMesuresProvider extends ChangeNotifier
    implements FichesMesuresProvider {
  FakeFichesMesuresProvider({List<FicheMesure> initialFiches = const []})
      : fiches = initialFiches;

  @override
  List<FicheMesure> fiches;

  @override
  bool get loading => false;

  @override
  String? get error => null;

  FicheMesure? addedFiche;
  String? updatedFicheId;
  Map<String, dynamic>? updatedChanges;
  Future<String?> Function(FicheMesure fiche)? onAdd;
  Future<String?> Function(String id, Map<String, dynamic> changes)? onUpdate;

  @override
  Future<void> load(String userId, {bool forceRefresh = false}) async {}

  @override
  List<FicheMesure> forClient(String clientId) =>
      fiches.where((fiche) => fiche.clientId == clientId).toList();

  @override
  Future<String?> addFiche(FicheMesure fiche) async {
    addedFiche = fiche;
    return onAdd?.call(fiche);
  }

  @override
  Future<String?> updateFiche(String id, Map<String, dynamic> changes) async {
    updatedFicheId = id;
    updatedChanges = changes;
    return onUpdate?.call(id, changes);
  }

  @override
  Future<String?> deleteFiche(String id) async => null;

  @override
  FicheMesure? byId(String id) {
    for (final fiche in fiches) {
      if (fiche.id == id) return fiche;
    }
    return null;
  }
}

Atelier testAtelier() {
  final now = DateTime(2026);
  return Atelier(
    id: 'owner-1',
    userId: 'owner-1',
    nomAtelier: 'Atelier test',
    specialite: 'Couture',
    createdAt: now,
    updatedAt: now,
  );
}

AtelierClient testClient({
  String id = 'client-1',
  String name = 'Aminata',
  String? phone = '90000000',
}) {
  final now = DateTime(2026);
  return AtelierClient(
    id: id,
    userId: 'owner-1',
    nomComplet: name,
    telephone: phone,
    createdAt: now,
    updatedAt: now,
  );
}

FicheMesure testFiche({
  String id = 'fiche-1',
  Map<String, dynamic> mesures = const {},
}) {
  final now = DateTime(2026);
  return FicheMesure(
    id: id,
    userId: 'owner-1',
    clientId: 'client-1',
    titre: 'Mesures existantes',
    mesures: mesures,
    notes: 'Notes existantes',
    createdAt: now,
    updatedAt: now,
  );
}
