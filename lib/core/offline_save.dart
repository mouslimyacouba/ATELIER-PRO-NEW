import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Result of an attempted Firestore write.
class SaveResult {
  const SaveResult({this.error, this.pendingSync = false});

  final String? error;
  final bool pendingSync;

  bool get ok => error == null;
}

/// Treats a Firestore write that is still pending after [grace] as locally
/// saved; a fast error is returned unchanged.
Future<SaveResult> saveWithOfflineGrace(
  Future<String?> operation, {
  Duration grace = const Duration(seconds: 4),
  VoidCallback? onLocalWrite,
}) async {
  onLocalWrite?.call();
  var timedOut = false;
  final error = await operation.timeout(
    grace,
    onTimeout: () {
      timedOut = true;
      return null;
    },
  );
  return SaveResult(error: error, pendingSync: timedOut && error == null);
}

bool shouldWriteOrderLocally(Iterable<ConnectivityResult> connectivity) =>
    connectivity.every((result) => result == ConnectivityResult.none);

/// Waits at most [grace] for the server to confirm a Firestore write.
///
/// Firestore applies the write to its local cache immediately; [true] means
/// the server has not acknowledged it by the grace deadline. Errors that
/// complete within the grace period are still propagated.
Future<bool> writeWithOfflineGrace(
  Future<void> Function() write, {
  Duration grace = const Duration(seconds: 4),
  VoidCallback? onLocalWrite,
}) async {
  onLocalWrite?.call();
  var timedOut = false;
  await write().timeout(
    grace,
    onTimeout: () {
      timedOut = true;
    },
  );
  return timedOut;
}
