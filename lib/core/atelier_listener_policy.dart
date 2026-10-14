bool shouldRestartAtelierListener({
  required String userId,
  required String? listeningUserId,
  required bool listenerFailed,
  required bool verifiedWhenListening,
  required bool userIsVerified,
}) {
  final identityChanged = userId != listeningUserId;
  final becameVerified = userIsVerified && !verifiedWhenListening;
  return identityChanged || (listenerFailed && becameVerified);
}
