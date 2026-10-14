import 'package:atelierpro_mobile/core/atelier_listener_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restarts after an identity change', () {
    expect(
      shouldRestartAtelierListener(
        userId: 'new-user',
        listeningUserId: 'old-user',
        listenerFailed: false,
        verifiedWhenListening: false,
        userIsVerified: false,
      ),
      isTrue,
    );
  });

  test('retries a failed listener when the same user becomes verified', () {
    expect(
      shouldRestartAtelierListener(
        userId: 'user',
        listeningUserId: 'user',
        listenerFailed: true,
        verifiedWhenListening: false,
        userIsVerified: true,
      ),
      isTrue,
    );
  });

  test('does not retry until a failed listener user becomes verified', () {
    expect(
      shouldRestartAtelierListener(
        userId: 'user',
        listeningUserId: 'user',
        listenerFailed: true,
        verifiedWhenListening: false,
        userIsVerified: false,
      ),
      isFalse,
    );
  });

  test('does not restart a failed listener for an already verified user', () {
    expect(
      shouldRestartAtelierListener(
        userId: 'user',
        listeningUserId: 'user',
        listenerFailed: true,
        verifiedWhenListening: true,
        userIsVerified: true,
      ),
      isFalse,
    );
  });
}
