 import 'dart:async';
import '../core/firestore_errors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/atelier.dart';

class AtelierProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _atelierSub;

  Atelier? _atelier;
  bool _loading = true;
  String? _error;

  Atelier? get atelier => _atelier;
  bool get loading => _loading;
  String? get error => _error;

  AtelierProvider() {
    // Écoute en temps réel dès qu'un utilisateur se connecte ; se réabonne
    // à chaque changement d'utilisateur, se désabonne à la déconnexion.
    // Avantage mode hors-ligne : Firestore sert immédiatement la dernière
    // valeur connue depuis le cache local si le réseau est indisponible,
    // puis met à jour automatiquement dès que la synchro reprend — pas
    // besoin de bouton "recharger".
    if (_auth.currentUser != null) {
      _listen(_auth.currentUser!.uid);
    } else {
      _loading = false;
    }
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listen(user.uid);
      } else {
        reset();
      }
    });
  }

  void _listen(String userId) {
    _loading = true;
    notifyListeners();
    _atelierSub?.cancel();
    _atelierSub = _firestore.collection('ateliers').doc(userId).snapshots().listen(
      (doc) {
        _atelier = doc.exists ? Atelier.fromMap(doc.id, doc.data()!) : null;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = friendlyFirestoreError(e);
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _atelierSub?.cancel();
    super.dispose();
  }

  Future<String?> createAtelier({
    required String nomAtelier,
    String? specialite,
    String? telephone,
    String? ville,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Utilisateur non connecté';
    final userId = user.uid;

    try {
      // S'assure que l'utilisateur est rechargé et que le jeton Auth est propagé
      try {
        await user.reload();
      } catch (_) {}

      final now = FieldValue.serverTimestamp();
      final docRef = _firestore.collection('ateliers').doc(userId);
      final atelierData = {
        'nomAtelier': nomAtelier,
        'specialite': specialite,
        'telephone': telephone,
        'ville': ville,
        'logoUrl': null,
        'createdAt': now,
        'updatedAt': now,
      };

      try {
        await docRef.set(atelierData, SetOptions(merge: true));
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          // Attente de propagation transitoire du jeton d'authentification (cas nouveau compte)
          await Future.delayed(const Duration(milliseconds: 600));
          await _auth.currentUser?.reload();
          await docRef.set(atelierData, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      // Pas besoin de mettre à jour `_atelier` manuellement : l'écoute
      // temps réel (_listen) reçoit ce changement automatiquement, y
      // compris hors ligne (écriture locale reflétée immédiatement).
      return null;
    } catch (e) {
      debugPrint('[AtelierProvider] Erreur createAtelier : $e');
      return friendlyFirestoreError(e);
    }
  }

  /// Accepte les mêmes clés "changes" que les écrans envoient déjà
  /// (héritées de la version Supabase, snake_case) et les traduit en
  /// camelCase côté Firestore — évite de retoucher les écrans appelants.
  Future<String?> updateAtelier(Map<String, dynamic> changes) async {
    if (_atelier == null) return 'Aucun atelier chargé';
    const keyMap = {
      'nom_atelier': 'nomAtelier',
      'logo_url': 'logoUrl',
    };
    final mapped = {
      for (final entry in changes.entries) (keyMap[entry.key] ?? entry.key): entry.value,
    };
    // Le métier se choisit une seule fois à la création; les règles Firestore
    // empêchent également sa modification côté serveur.
    mapped.remove('specialite');
    mapped['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore.collection('ateliers').doc(_atelier!.id).update(mapped);
      return null;
    } catch (e) {
      return friendlyFirestoreError(e);
    }
  }

  Future<String?> updateLogo(String logoUrl) => updateAtelier({'logo_url': logoUrl});

  /// Supprime toutes les données liées avant l'atelier. Le compte Firebase
  /// Auth est supprimé ensuite par `AuthProvider.deleteAccount`, pendant que
  /// les règles Firestore exigent encore une session valide.
  Future<String?> deleteAtelier() async {
    final user = _auth.currentUser;
    if (user == null) return 'Utilisateur non connecté';
    final userId = user.uid;

    try {
      // Pas de contrainte de clé étrangère côté Firestore : ces collections
      // peuvent être supprimées en parallèle. L'atelier reste jusqu'à la fin.
      await Future.wait([
        _deleteAllWhereUserId('fiches', userId),
        _deleteAllWhereUserId('paiements', userId),
        _deleteAllWhereUserId('commandes', userId),
        _deleteAllWhereUserId('clients', userId),
        _deleteAllWhereUserId('stock', userId),
        _deleteAllWhereUserId('modeles', userId),
        _deleteAllWhereUserId('historique_modifications', userId),
      ]);
      await _firestore.collection('compteurs').doc(userId).delete();
      await _firestore.collection('ateliers').doc(userId).delete();
      return null;
    } catch (e) {
      return friendlyFirestoreError(e);
    }
  }

  Future<void> _deleteAllWhereUserId(String collection, String userId) async {
    final snapshot = await _firestore.collection(collection).where('userId', isEqualTo: userId).get();
    // Firestore limite un batch à 500 opérations : on découpe par sécurité.
    for (var i = 0; i < snapshot.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void reset() {
    _atelierSub?.cancel();
    _atelier = null;
    _loading = false;
    notifyListeners();
  }
}
