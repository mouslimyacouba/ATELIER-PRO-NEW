import 'dart:math' as math;

/// Limiteur d'essais de connexion côté appareil.
///
/// Après [maxAttempts] échecs consécutifs, la connexion est suspendue pendant
/// [baseLock], puis la durée double à chaque nouvel échec (plafonnée à
/// [maxLock]). C'est un confort et une première barrière : la vraie limite
/// reste celle de Firebase (`too-many-requests`), qui s'applique côté serveur.
/// L'état n'est pas conservé si l'application est fermée.
class AttemptGuard {
  AttemptGuard({
    this.maxAttempts = 5,
    this.baseLock = const Duration(seconds: 30),
    this.maxLock = const Duration(minutes: 8),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxAttempts;
  final Duration baseLock;
  final Duration maxLock;
  final DateTime Function() _now;

  int _failures = 0;
  DateTime? _lockedUntil;

  int get failures => _failures;

  Duration get remaining {
    final until = _lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isLocked => remaining > Duration.zero;

  /// À appeler après un identifiant ou un mot de passe incorrect.
  void recordFailure() {
    _failures++;
    if (_failures < maxAttempts) return;
    final steps = math.min(_failures - maxAttempts, 10);
    var lock = baseLock * (1 << steps);
    if (lock > maxLock) lock = maxLock;
    _lockedUntil = _now().add(lock);
  }

  /// Verrouille immédiatement (ex. : Firebase répond `too-many-requests`).
  void lockFor(Duration duration) {
    final capped = duration > maxLock ? maxLock : duration;
    final until = _now().add(capped);
    final current = _lockedUntil;
    if (current == null || until.isAfter(current)) _lockedUntil = until;
  }

  /// À appeler après une connexion réussie.
  void recordSuccess() {
    _failures = 0;
    _lockedUntil = null;
  }
}
