import 'dart:async';

import 'package:atelierpro_mobile/core/offline_save.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('writeWithOfflineGrace', () {
    test('returns false when server acknowledgement is quick', () async {
      final pending = await writeWithOfflineGrace(
        () async {},
        grace: const Duration(milliseconds: 30),
      );

      expect(pending, isFalse);
    });

    test('returns true when acknowledgement exceeds grace', () async {
      final completer = Completer<void>();
      final pending = await writeWithOfflineGrace(
        () => completer.future,
        grace: const Duration(milliseconds: 10),
      );

      expect(pending, isTrue);
      completer.complete();
    });

    test('rethrows a write error within the grace period', () async {
      await expectLater(
        writeWithOfflineGrace(
          () async => throw StateError('write failed'),
          grace: const Duration(milliseconds: 30),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('order write connectivity decision', () {
    test('uses local write only when every connection is none', () {
      expect(
        shouldWriteOrderLocally([ConnectivityResult.none]),
        isTrue,
      );
      expect(
        shouldWriteOrderLocally([ConnectivityResult.wifi]),
        isFalse,
      );
      expect(
        shouldWriteOrderLocally([
          ConnectivityResult.wifi,
          ConnectivityResult.none,
        ]),
        isFalse,
      );
    });
  });
}
