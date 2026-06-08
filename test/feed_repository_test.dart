import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voice_of_polban/api/feed_repository.dart';
import 'package:voice_of_polban/storage/cached_post.dart';
import 'package:voice_of_polban/storage/local_bookmark.dart';
import 'package:voice_of_polban/storage/local_vote.dart';

// Mocks
class MockCachedPostBox extends Mock implements Box<CachedPost> {}
class MockBookmarkBox extends Mock implements Box<LocalBookmark> {}
class MockVoteBox extends Mock implements Box<LocalVote> {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakeFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Exception? errorToThrow;
  final dynamic returnValue;

  FakeFilterBuilder({this.errorToThrow, this.returnValue});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    if (errorToThrow != null) throw errorToThrow!;
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakeTransformBuilderList(errorToThrow: errorToThrow, returnValue: returnValue);
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    if (errorToThrow != null) {
      if (onError != null) return onError(errorToThrow!);
      throw errorToThrow!;
    }
    return onValue(returnValue == null ? [] : (returnValue is List ? returnValue as List<Map<String, dynamic>> : [returnValue as Map<String, dynamic>]));
  }
}

class FakeTransformBuilderList extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final Exception? errorToThrow;
  final dynamic returnValue;

  FakeTransformBuilderList({this.errorToThrow, this.returnValue});
  
  @override
  Future<S> then<S>(
    FutureOr<S> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    if (errorToThrow != null) {
      if (onError != null) return onError(errorToThrow!);
      throw errorToThrow!;
    }
    return onValue(returnValue == null ? [] : (returnValue is List ? returnValue as List<Map<String, dynamic>> : [returnValue as Map<String, dynamic>]));
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakeTransformBuilderMap(errorToThrow: errorToThrow, returnValue: returnValue);
  }
}

class FakeTransformBuilderMap extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Exception? errorToThrow;
  final dynamic returnValue;

  FakeTransformBuilderMap({this.errorToThrow, this.returnValue});

  @override
  Future<S> then<S>(
    FutureOr<S> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) async {
    if (errorToThrow != null) {
      if (onError != null) return onError(errorToThrow!);
      throw errorToThrow!;
    }
    return onValue(returnValue as Map<String, dynamic>?);
  }
}

void main() {
  late FeedRepository repository;
  late MockCachedPostBox mockCachedPostBox;
  late MockBookmarkBox mockBookmarkBox;
  late MockVoteBox mockVoteBox;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockCachedPostBox = MockCachedPostBox();
    mockBookmarkBox = MockBookmarkBox();
    mockVoteBox = MockVoteBox();
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    repository = FeedRepository();
    repository.mockCachedPostsBox = mockCachedPostBox;
    repository.mockBookmarkBox = mockBookmarkBox;
    repository.mockVoteBox = mockVoteBox;
    repository.mockSupabase = mockSupabase;

    final mockAuth = MockGoTrueClient();
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    when(() => mockSupabase.from(any())).thenAnswer((_) => mockQueryBuilder);
    
    registerFallbackValue(LocalBookmark(bookmarkId: '', postId: '', userId: '', isSynced: false));
  });

  group('FeedRepository Bookmark Tests (White Box)', () {

    // TC-WB-01
    test('TC-WB-01: toggleBookmark - Adds new bookmark when it does not exist', () async {
      repository.mockUserId = 'user123';
      final postId = 'post1';

      // Setup Box to say bookmark doesn't exist
      when(() => mockBookmarkBox.values).thenReturn([]);
      when(() => mockBookmarkBox.put(any(), any())).thenAnswer((_) async => {});
      
      // Mock _cachedPostsBox
      when(() => mockCachedPostBox.containsKey(postId)).thenReturn(true);

      // Setup Supabase mock for insert -> select -> maybeSingle
      when(() => mockQueryBuilder.insert(any())).thenAnswer(
        (_) => FakeFilterBuilder(returnValue: {'bookmark_id': 'b-123'})
      );

      await repository.toggleBookmark(postId);

      // Verify remote insert
      verify(() => mockQueryBuilder.insert({'user_id': 'user123', 'post_id': 'post1'})).called(1);
      
      // Verify local put
      verify(() => mockBookmarkBox.put(any(), any())).called(1);
    });

    // TC-WB-02
    test('TC-WB-02: toggleBookmark - Deletes existing bookmark', () async {
      repository.mockUserId = 'user123';
      final postId = 'post1';
      final existingBookmark = LocalBookmark(bookmarkId: 'b-123', postId: postId, userId: 'user123', isSynced: true);

      // Setup Box to say bookmark exists
      when(() => mockBookmarkBox.values).thenReturn([existingBookmark]);
      when(() => mockBookmarkBox.delete(any())).thenAnswer((_) async => {});

      // Setup Supabase mock
      when(() => mockQueryBuilder.delete()).thenAnswer((_) => FakeFilterBuilder());

      await repository.toggleBookmark(postId);

      // Verify remote delete
      verify(() => mockQueryBuilder.delete()).called(1);
      
      // Verify local delete
      verify(() => mockBookmarkBox.delete('b-123')).called(1);
    });

    // TC-WB-03
    test('TC-WB-03: toggleBookmark - Throws exception when user not logged in', () async {
      repository.mockUserId = null; // No user
      final postId = 'post1';

      expect(
        () async => await repository.toggleBookmark(postId),
        throwsA(isA<Exception>()),
      );

      // Verify nothing happened
      verifyNever(() => mockBookmarkBox.values);
      verifyNever(() => mockQueryBuilder.insert(any()));
      verifyNever(() => mockQueryBuilder.delete());
    });

    // TC-WB-04
    test('TC-WB-04: getOfflineBookmarks - Retrieves correctly', () {
      repository.mockUserId = 'user123';
      
      final bookmark1 = LocalBookmark(bookmarkId: 'b1', postId: 'p1', userId: 'user123', isSynced: true);
      final bookmark2 = LocalBookmark(bookmarkId: 'b2', postId: 'p2', userId: 'user123', isSynced: true);
      
      final post1 = CachedPost(postId: 'p1', cachedData: '', cachedAt: DateTime.now());
      final post2 = CachedPost(postId: 'p2', cachedData: '', cachedAt: DateTime.now());

      when(() => mockBookmarkBox.values).thenReturn([bookmark1, bookmark2]);
      when(() => mockCachedPostBox.get('p1')).thenReturn(post1);
      when(() => mockCachedPostBox.get('p2')).thenReturn(post2);

      final result = repository.getOfflineBookmarks();

      expect(result.length, 2);
      expect(result.map((e) => e.postId), containsAll(['p1', 'p2']));
    });
  });
}
