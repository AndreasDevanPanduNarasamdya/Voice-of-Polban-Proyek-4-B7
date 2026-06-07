import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voice_of_polban/processing/sync_worker.dart';
import 'package:voice_of_polban/storage/sync_queue.dart';

// 1. Mocks
class MockBox extends Mock implements Box<SyncQueue> {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// 2. Custom Fake (Handles Supabase async chaining and offline exceptions safely)
class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final Exception? errorToThrow;

  FakeFilterBuilder({this.errorToThrow});

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    if (errorToThrow != null) throw errorToThrow!;
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic value) onValue, {
    Function? onError,
  }) async {
    if (errorToThrow != null) {
      if (onError != null) return onError(errorToThrow!);
      throw errorToThrow!;
    }
    return onValue([]);
  }
}

void main() {
  late SyncWorker syncWorker;
  late MockBox mockBox;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockBox = MockBox();
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    syncWorker = SyncWorker();
    syncWorker.mockBox = mockBox;
    syncWorker.mockSupabase = mockSupabase;

    when(() => mockSupabase.from(any())).thenAnswer((_) => mockQueryBuilder);

    registerFallbackValue(const <String, dynamic>{});
    registerFallbackValue(
      SyncQueue(
        queueId: '',
        actionType: '',
        payload: '',
        isProcessed: false,
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() {
    syncWorker.mockBox = null;
    syncWorker.mockSupabase = null;
  });

  group('SyncWorker CRUD & Edge Cases', () {
    // ==========================================
    // 1. CREATE (Upload Draft)
    // ==========================================
    test('CREATE: Successfully processes UPLOAD_DRAFT', () async {
      final dummyTask = SyncQueue(
        queueId: 'q1',
        actionType: 'UPLOAD_DRAFT',
        payload: jsonEncode({
          'postId': 'p1',
          'title': 'A',
          'content': 'B',
          'userId': 'u1',
          'status': 'draft',
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      when(() => mockBox.values).thenReturn([dummyTask]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenAnswer((_) => FakeFilterBuilder());

      await syncWorker.processSyncQueue();

      verify(() => mockQueryBuilder.upsert(any())).called(1);
      expect(dummyTask.isProcessed, isTrue);
      verify(() => mockBox.put('q1', dummyTask)).called(1);
    });

    // ==========================================
    // 2. UPDATE (Update Draft)
    // ==========================================
    test('UPDATE: Successfully processes UPDATE_DRAFT', () async {
      final dummyTask = SyncQueue(
        queueId: 'q2',
        actionType: 'UPDATE_DRAFT',
        payload: jsonEncode({
          'postId': 'p2',
          'title': 'Updated Title',
          'content': 'Updated Content',
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      when(() => mockBox.values).thenReturn([dummyTask]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});
      when(
        () => mockQueryBuilder.update(any()),
      ).thenAnswer((_) => FakeFilterBuilder());

      await syncWorker.processSyncQueue();

      verify(
        () => mockQueryBuilder.update({
          'title': 'Updated Title',
          'content': 'Updated Content',
        }),
      ).called(1); // Verified it passed the right data to Supabase

      expect(dummyTask.isProcessed, isTrue);
    });

    // ==========================================
    // 3. DELETE (Delete Post)
    // ==========================================
    test('DELETE: Successfully processes DELETE_POST', () async {
      final dummyTask = SyncQueue(
        queueId: 'q3',
        actionType: 'DELETE_POST',
        payload: jsonEncode({'postId': 'p3'}),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      when(() => mockBox.values).thenReturn([dummyTask]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});
      when(
        () => mockQueryBuilder.delete(),
      ).thenAnswer((_) => FakeFilterBuilder());

      await syncWorker.processSyncQueue();

      verify(() => mockQueryBuilder.delete()).called(1);
      expect(dummyTask.isProcessed, isTrue);
    });

    // ==========================================
    // 4. EDGE CASE: Network Crash
    // ==========================================
    test('RESILIENCE: Fails gracefully when offline', () async {
      final dummyTask = SyncQueue(
        queueId: 'q4',
        actionType: 'DELETE_POST', // Any action works here
        payload: jsonEncode({'postId': 'p4'}),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      when(() => mockBox.values).thenReturn([dummyTask]);
      when(() => mockQueryBuilder.delete()).thenAnswer(
        (_) => FakeFilterBuilder(errorToThrow: Exception('No Internet')),
      );

      await syncWorker.processSyncQueue();

      expect(dummyTask.isProcessed, isFalse); // Keeps it in queue for next time
      verifyNever(() => mockBox.put(any(), any()));
    });

    // ==========================================
    // 5. EDGE CASE: Corrupt JSON
    // ==========================================
    test(
      'RESILIENCE: Ignores tasks with corrupt JSON payload without crashing',
      () async {
        final corruptTask = SyncQueue(
          queueId: 'q5',
          actionType: 'UPLOAD_DRAFT',
          payload: '{ bad_json_string: ', // Missing quotes, brackets, etc.
          isProcessed: false,
          createdAt: DateTime.now(),
        );

        when(() => mockBox.values).thenReturn([corruptTask]);

        // If jsonDecode crashes the whole method, this test will fail.
        // If the try/catch block works, the test will pass.
        await syncWorker.processSyncQueue();

        expect(corruptTask.isProcessed, isFalse);
        verifyNever(() => mockQueryBuilder.upsert(any()));
      },
    );
  });
}
