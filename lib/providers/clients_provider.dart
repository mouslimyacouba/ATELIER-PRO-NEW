import 'dart:async';
import '../core/firestore_errors.dart';
import '../core/client_deletion_policy.dart';
import '../core/offline_save.dart';
import '../core/sync_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client.dart';

class ClientsProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _currentUserId;

  List<AtelierClient> _clients = [];
  bool _loading = false;
  String? _error;

  List<AtelierClient> get clients => _clients;
  bool get loading => _loading;
  String? get error => _error;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// S'abonne en temps réel aux clients de cet utilisateur. Hors ligne,
  /// Firestore sert immédiatement la dernière version connue depuis le
  /// cache local ; les écritures faites hors ligne (ajout/modif/suppression)
  /// apparaissent aussi immédiatement ici (cache local), puis se
  /// synchronisent en arrière-plan dès que le réseau revient — aucune
  /// action de l'utilisateur n'est nécessaire.
  ///
  /// Retourne un Future qui se termine dès la première donnée reçue (utile
  /// pour le pull-to-refresh), sans se désabonner : l'écoute reste active
  /// pour les mises à jour suivantes.
  Future<void> load(String userId, {bool forceRefresh = false}) {
    if (!forceRefresh && _currentUserId == userId && _sub != null) {
      return Future.value(); // déjà abonné, rien à refaire
    }
    _currentUserId = userId;
    _loading = true;
    notifyListeners();

    final completer = Completer<void>();
    final firstSnapshotTimer =
        kDebugMode ? (Stopwatch()..start()) : null;
    _sub?.cancel();
    _sub = _firestore
        .collection('clients')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _clients = snapshot.docs
            .map((d) => AtelierClient.fromMap(d.id, d.data()))
            .toList();
        // Tri serveur via orderBy() — plus de .sort() côté client
        _loading = false;
        _error = null;
        notifyListeners();
        if (firstSnapshotTimer != null && !completer.isCompleted) {
          debugPrint(
            '[PERF] clients first snapshot: '
            '${firstSnapshotTimer.elapsedMilliseconds}ms '
            'cache=${snapshot.metadata.isFromCache} docs=${snapshot.docs.length}',
          );
        }
        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        _error = friendlyFirestoreError(e);
        _loading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<String?> addClient(AtelierClient client) async {
    try {
      await writeWithOfflineGrace(
        () => _firestore.collection('clients').add(client.toInsertMap()),
        onLocalWrite: SyncStatus.instance.onLocalWrite,
      );
      return null; // l'écoute temps réel met à jour _clients automatiquement
    } catch (e) {
      return friendlyFirestoreError(e);
    }
  }

  /// Accepte les mêmes clés que les écrans envoient déjà (héritées de la
  /// version Supabase, snake_case) et les traduit en camelCase Firestore.
  Future<String?> updateClient(String id, Map<String, dynamic> changes) async {
    const keyMap = {
      'nom_complet': 'nomComplet',
      'photo_url': 'photoUrl',
    };
    final mapped = {
      for (final entry in changes.entries)
        (keyMap[entry.key] ?? entry.key): entry.value,
    };
    mapped['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await writeWithOfflineGrace(
        () => _firestore.collection('clients').doc(id).update(mapped),
        onLocalWrite: SyncStatus.instance.onLocalWrite,
      );
      return null;
    } catch (e) {
      return friendlyFirestoreError(e);
    }
  }

  Future<String?> updatePhoto(String clientId, String photoUrl) =>
      updateClient(clientId, {'photo_url': photoUrl});

  /// Le client est supprimable uniquement sans commande ni paiement associé.
  /// Ses fiches de mesures sont supprimées avec lui, mais l'historique
  /// comptable n'est jamais supprimé en cascade.
  Future<String?> deleteClient(String id, String userId) async {
    try {
      final commandes = await _firestore
          .collection('commandes')
          .where('userId', isEqualTo: userId)
          .where('clientId', isEqualTo: id)
          .limit(1)
          .get();
      final paiements = await _firestore
          .collection('paiements')
          .where('userId', isEqualTo: userId)
          .where('clientId', isEqualTo: id)
          .limit(1)
          .get();
      final blocked = clientDeletionBlockMessage(
        orderCount: commandes.size,
        paymentCount: paiements.size,
      );
      if (blocked != null) return blocked;

      final fiches = await _firestore
          .collection('fiches')
          .where('userId', isEqualTo: userId)
          .where('clientId', isEqualTo: id)
          .get();

      final refs = [
        ...fiches.docs.map((fiche) => fiche.reference),
        _firestore.collection('clients').doc(id),
      ];
      for (var i = 0; i < refs.length; i += 400) {
        final batch = _firestore.batch();
        for (final ref in refs.skip(i).take(400)) {
          batch.delete(ref);
        }
        await writeWithOfflineGrace(
          () => batch.commit(),
          onLocalWrite: SyncStatus.instance.onLocalWrite,
        );
      }
      return null;
    } catch (e) {
      return friendlyFirestoreError(e);
    }
  }

  AtelierClient? byId(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
