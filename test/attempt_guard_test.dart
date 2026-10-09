import 'package:flutter_test/flutter_test.dart';
import 'package:atelierpro_mobile/core/attempt_guard.dart';

void main() {
  late DateTime now;
  late AttemptGuard guard;

  setUp(() {
    now = DateTime(2026, 10, 9, 12);
    guard = AttemptGuard(now: () => now);
  });

  test('ne verrouille pas avant le nombre maximal d\'échecs', () {
    for (var i = 0; i < 4; i++) {
      guard.recordFailure();
    }
    expect(guard.isLocked, isFalse);
    expect(guard.failures, 4);
  });

  test('verrouille 30 s au 5e échec puis se déverrouille', () {
    for (var i = 0; i < 5; i++) {
      guard.recordFailure();
    }
    expect(guard.isLocked, isTrue);
    expect(guard.remaining, const Duration(seconds: 30));

    now = now.add(const Duration(seconds: 29));
    expect(guard.isLocked, isTrue);

    now = now.add(const Duration(seconds: 2));
    expect(guard.isLocked, isFalse);
    expect(guard.remaining, Duration.zero);
  });

  test('double la durée à chaque échec suivant, plafonnée à 8 minutes', () {
    for (var i = 0; i < 5; i++) {
      guard.recordFailure();
    }
    now = now.add(const Duration(minutes: 1));
    guard.recordFailure(); // 6e : 60 s
    expect(guard.remaining, const Duration(seconds: 60));

    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(minutes: 10));
      guard.recordFailure();
    }
    expect(guard.remaining, const Duration(minutes: 8));
  });

  test('une connexion réussie remet tout à zéro', () {
    for (var i = 0; i < 5; i++) {
      guard.recordFailure();
    }
    guard.recordSuccess();
    expect(guard.isLocked, isFalse);
    expect(guard.failures, 0);
  });

  test('lockFor verrouille tout de suite et ne raccourcit jamais un verrou', () {
    guard.lockFor(const Duration(minutes: 1));
    expect(guard.remaining, const Duration(minutes: 1));

    guard.lockFor(const Duration(seconds: 10));
    expect(guard.remaining, const Duration(minutes: 1));
  });
}
