import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:voice_of_polban/processing/sync_worker.dart';

class MockHiveBox extends Mock implements Box {}

void main() {
  group('Sync Worker Tests (Tester: Hafiz Zulhakim)', () {
    test(
      'UT-03: SyncWorker.processSyncQueue() Positive - Process pending queue on reconnect',
      () async {
        final mockSyncBox = MockHiveBox();
        // Simulating 1 entry with isProcessed = false
        when(() => mockSyncBox.values).thenReturn([
          {'isProcessed': false},
        ]);

        final worker = SyncWorker(box: mockSyncBox);
        await worker.processSyncQueue();

        expect(worker.isSyncing, false);
      },
    );
  });
}
