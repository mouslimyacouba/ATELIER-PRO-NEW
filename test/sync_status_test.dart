import 'dart:async';

import 'package:atelierpro_mobile/core/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending state clears only after the latest write is acknowledged',
      () async {
    final acknowledgements = <Completer<void>>[];
    final status = SyncStatus(
      waitForPendingWrites: () {
        final acknowledgement = Completer<void>();
        acknowledgements.add(acknowledgement);
        return acknowledgement.future;
      },
    );
    addTearDown(status.dispose);

    status.onLocalWrite();
    status.onLocalWrite();
    expect(status.hasPending, isTrue);
    expect(acknowledgements, hasLength(2));

    acknowledgements[0].complete();
    await Future<void>.delayed(Duration.zero);
    expect(status.hasPending, isTrue);

    acknowledgements[1].complete();
    await Future<void>.delayed(Duration.zero);
    expect(status.hasPending, isFalse);
  });
}
