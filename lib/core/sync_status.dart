import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tracks writes stored locally that have not yet been acknowledged by Firestore.
class SyncStatus extends ChangeNotifier {
  SyncStatus({Future<void> Function()? waitForPendingWrites})
      : _wait = waitForPendingWrites ??
            (() => FirebaseFirestore.instance.waitForPendingWrites());

  static final SyncStatus instance = SyncStatus();

  final Future<void> Function() _wait;
  bool _hasPending = false;
  int _generation = 0;

  bool get hasPending => _hasPending;

  void onLocalWrite() {
    final generation = ++_generation;
    if (!_hasPending) {
      _hasPending = true;
      notifyListeners();
    }
    Future<void>.sync(_wait).then((_) {
      if (generation == _generation && _hasPending) {
        _hasPending = false;
        notifyListeners();
      }
    }).catchError((Object _) {});
  }
}
