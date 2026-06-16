import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_enums.dart';
import '../storage/cached_post.dart';
import '../storage/cached_user.dart';
import '../storage/comment_model.dart';
import '../storage/local_bookmark.dart';
import '../storage/local_vote.dart';

class FeedRepository {
  static const String _cachedPostsBoxName = 'cached_post_box';
  static const String _bookmarkBoxName = 'local_bookmark_box';
  static const String _voteBoxName = 'local_vote_box';

  final Uuid _uuid = const Uuid();

  // --- ADDED FOR TESTABILITY ---
  @visibleForTesting
  Box<CachedPost>? mockCachedPostsBox;
  @visibleForTesting
  Box<LocalBookmark>? mockBookmarkBox;
  @visibleForTesting
  Box<LocalVote>? mockVoteBox;
  @visibleForTesting
  SupabaseClient? mockSupabase;
  @visibleForTesting
  String? mockUserId;
  // -----------------------------

  SupabaseClient get _supabase => mockSupabase ?? Supabase.instance.client;

  Box<CachedPost> get _cachedPostsBox =>
      mockCachedPostsBox ?? Hive.box<CachedPost>(_cachedPostsBoxName);
  Box<LocalBookmark> get _bookmarkBox =>
      mockBookmarkBox ?? Hive.box<LocalBookmark>(_bookmarkBoxName);
  Box<LocalVote> get _voteBox =>
      mockVoteBox ?? Hive.box<LocalVote>(_voteBoxName);

  String? get _currentUserId {
    // 🚨 1. Return the mock user ID immediately if testing
    if (mockUserId != null) return mockUserId;

    try {
      if (Hive.isBoxOpen('session_box')) {
        final sessionBox = Hive.box('session_box');
        final userId = sessionBox.get('logged_in_user_id');
        if (userId != null) return userId.toString();
      }
      // 🚨 2. Route fallback through the testable _supabase getter
      return _supabase.auth.currentUser?.id;
    } catch (_) {
      return _supabase.auth.currentUser?.id;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  List<String> _extractImageUrls(Map<String, dynamic> map) {
    final attachments = map['attachments'] as List<dynamic>?;
    if (attachments == null || attachments.isEmpty) {
      return <String>[];
    }
    final details = attachments.first['attachment_details'] as List<dynamic>?;
    if (details == null || details.isEmpty) {
      return <String>[];
    }
    return details
        .map((detail) => detail['file_path'].toString())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
  }

  DateTime _parsePostDate(dynamic rawValue) {
    if (rawValue is String) {
      return DateTime.tryParse(rawValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  CachedPost? _buildCachedPost(Map<String, dynamic> map) {
    final postId = (map['post_id'] ?? '').toString();
    if (postId.isEmpty) {
      return null;
    }

    return CachedPost(
      postId: postId,
      cachedData: jsonEncode({
        'title': (map['title'] ?? '').toString(),
        'content': (map['content'] ?? '').toString(),
        'author_id': map['author_id']?.toString() ?? '',
        'imageUrls': _extractImageUrls(map),
        'hashtags': _extractHashtags(map),
        'status': (map['status'] ?? PostStatus.published.name).toString(),
        if (map['rejection_note'] != null)
          'rejection_note': map['rejection_note'].toString(),
      }),
      cachedAt: _parsePostDate(map['created_at']),
    );
  }

  Future<CachedPost?> _fetchAndCachePostById(String postId) async {
    if (postId.trim().isEmpty) return null;

    // 🚨 FIX: Routed through testable getter
    try {
      final row = await _supabase
          .from('posts')
          .select('''
            post_id, title, content, author_id, status, created_at, rejection_note, 
            attachments(attachment_details(file_path)),
            hashtags:post_hashtags(hashtags(name))
          ''')
          .eq('post_id', postId)
          .maybeSingle();

      if (row == null) return null;

      final cachedPost = _buildCachedPost(
        Map<String, dynamic>.from(row as Map),
      );
      if (cachedPost != null) {
        await _cachedPostsBox.put(cachedPost.postId, cachedPost);
      }
      return cachedPost;
    } catch (e) {
      debugPrint('Failed to fetch/cache post $postId: $e');
      return null;
    }
  }

  Future<List<CachedPost>> _fetchAndCachePostsByIds(
    List<String> postIds,
  ) async {
    final uniquePostIds = postIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (uniquePostIds.isEmpty) return <CachedPost>[];

    // 🚨 FIX: Routed through testable getter
    try {
      final rows = await _supabase
          .from('posts')
          .select('''
            post_id, title, content, author_id, status, created_at, rejection_note, 
            attachments(attachment_details(file_path)),
            hashtags:post_hashtags(hashtags(name))
          ''')
          .inFilter('post_id', uniquePostIds);

      final List<CachedPost> cachedPosts = [];
      for (final row in rows as List) {
        final cachedPost = _buildCachedPost(
          Map<String, dynamic>.from(row as Map),
        );
        if (cachedPost == null) {
          continue;
        }
        await _cachedPostsBox.put(cachedPost.postId, cachedPost);
        cachedPosts.add(cachedPost);
      }
      return cachedPosts;
    } catch (e) {
      debugPrint('Failed to fetch/cache posts by ids: $e');
      return <CachedPost>[];
    }
  }

  Future<void> _syncAuthors(List rows, Box<CachedUser> usersBox) async {
    final authorIds = rows
        .map((r) => (r as Map)['author_id'].toString())
        .toSet()
        .toList();

    if (authorIds.isEmpty) return;

    // 🚨 FIX: Routed through testable getter
    try {
      final userRows = await _supabase
          .from('users')
          .select('user_id, name, avatar_url, role')
          .inFilter('user_id', authorIds);

      for (final u in userRows as List) {
        final umap = Map<String, dynamic>.from(u as Map);
        final uid = umap['user_id'].toString();
        UserRole urole = UserRole.reader;
        try {
          urole = UserRole.values.byName(umap['role'].toString().toLowerCase());
        } catch (_) {}
        await usersBox.put(
          uid,
          CachedUser(
            userId: uid,
            name: umap['name'].toString(),
            email: '',
            role: urole,
            avatarUrl: umap['avatar_url']?.toString() ?? '',
          ),
        );
      }
    } catch (userErr) {
      debugPrint('Failed to sync authors independently: $userErr');
    }
  }

  // ─── Feed ───────────────────────────────────────────────────────────────────

  List<CachedPost> getOfflinePosts() =>
      _cachedPostsBox.values.toList(growable: false);

  Future<List<CachedPost>> fetchFeed() async {
    // 🚨 FIX: Routed through testable getter
    try {
      final rows = await _supabase
          .from('posts')
          .select('''
            post_id, title, content, author_id, status, created_at, 
            attachments(attachment_details(file_path)),
            hashtags:post_hashtags(hashtags(name))
          ''')
          .eq('status', PostStatus.published.name)
          .order('created_at', ascending: false);

      final usersBox = Hive.box<CachedUser>('cached_user_box');
      await _syncAuthors(rows as List, usersBox);

      final List<CachedPost> posts = [];
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? '').toString();
        if (postId.isEmpty) {
          continue;
        }

        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details =
              attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final cachedPost = _buildCachedPost(map);
        if (cachedPost == null) continue;

        await _cachedPostsBox.put(postId, cachedPost);
        posts.add(cachedPost);
      }
      return posts;
    } catch (e) {
      debugPrint('Failed to fetch feed from Supabase: $e');
      return getOfflinePosts();
    }
  }

  Future<List<CachedPost>> searchPosts(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return <CachedPost>[];
    }

    // 🚨 FIX: Routed through testable getter
    try {
      final rows = await _supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, attachments(attachment_details(file_path))',
          )
          .eq('status', PostStatus.published.name)
          .or('title.ilike.%$trimmedQuery%,content.ilike.%$trimmedQuery%')
          .order('created_at', ascending: false)
          .limit(20);

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final cachedPost = _buildCachedPost(
          Map<String, dynamic>.from(row as Map),
        );
        if (cachedPost == null) {
          continue;
        }
        posts.add(cachedPost);
      }
      return posts;
    } catch (e) {
      debugPrint('Failed to search posts from Supabase: $e');
      return <CachedPost>[];
    }
  }

  // ─── Comments ───────────────────────────────────────────────────────────────

  Future<List<CommentModel>> fetchComments(String postId) async {
    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) return <CommentModel>[];

    // 🚨 FIX: Routed through testable getter
    try {
      final rows = await _supabase
          .from('comments')
          .select('*, users(name)')
          .eq('post_id', trimmedPostId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => CommentModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Failed to fetch comments for $trimmedPostId: $e');
      return <CommentModel>[];
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Guests cannot comment. Please sign in first.');
    }

    final trimmedPostId = postId.trim();
    final trimmedContent = content.trim();
    if (trimmedPostId.isEmpty) throw ArgumentError('postId cannot be empty.');
    if (trimmedContent.isEmpty) throw ArgumentError('content cannot be empty.');

    // 🚨 FIX: Routed through testable getter
    await _supabase.from('comments').insert({
      'post_id': trimmedPostId,
      'user_id': userId,
      'content': trimmedContent,
    });

    final cachedPost = _cachedPostsBox.get(trimmedPostId);
    if (cachedPost != null) {
      final data = Map<String, dynamic>.from(
        jsonDecode(cachedPost.cachedData) as Map,
      );
      final currentCount = data['comment_count'] ?? 0;
      data['comment_count'] =
          (currentCount is num
              ? currentCount.toInt()
              : int.tryParse(currentCount.toString()) ?? 0) +
          1;
      cachedPost.cachedData = jsonEncode(data);
      cachedPost.cachedAt = DateTime.now();
      await _cachedPostsBox.put(trimmedPostId, cachedPost);
    }
  }

  // ─── Bookmarks ──────────────────────────────────────────────────────────────

  List<CachedPost> getOfflineBookmarks() {
    final userId = _currentUserId;
    if (userId == null) return <CachedPost>[];

    final bookmarkedPostIds = _bookmarkBox.values
        .where((bookmark) => bookmark.userId == userId)
        .map((bookmark) => bookmark.postId)
        .toSet();

    if (bookmarkedPostIds.isEmpty) return <CachedPost>[];

    return bookmarkedPostIds
        .map(_cachedPostsBox.get)
        .whereType<CachedPost>()
        .toList(growable: false);
  }

  Future<void> toggleBookmark(String postId) async {
    final userId = _currentUserId;
    if (userId == null || postId.trim().isEmpty) {
      debugPrint('toggleBookmark skipped: missing user or post id.');
      return;
    }

    final existingEntry = _bookmarkBox.values.cast<LocalBookmark?>().firstWhere(
      (b) => b != null && b.userId == userId && b.postId == postId,
      orElse: () => null,
    );

    if (existingEntry != null) {
      try {
        // 🚨 FIX: Routed through testable getter
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      } catch (e) {
        debugPrint('Failed to delete remote bookmark for $postId: $e');
      }
      await _bookmarkBox.delete(existingEntry.bookmarkId);
      return;
    }

    String bookmarkId = _uuid.v4();
    try {
      // 🚨 FIX: Routed through testable getter
      final inserted = await _supabase
          .from('bookmarks')
          .insert({'user_id': userId, 'post_id': postId})
          .select('bookmark_id')
          .maybeSingle();

      if (inserted != null) {
        final map = Map<String, dynamic>.from(inserted as Map);
        bookmarkId = (map['bookmark_id'] ?? bookmarkId).toString();
      }
    } catch (e) {
      debugPrint('Failed to insert remote bookmark for $postId: $e');
    }

    final bookmark = LocalBookmark(
      bookmarkId: bookmarkId,
      postId: postId,
      userId: userId,
      isSynced: true,
    );
    await _bookmarkBox.put(bookmark.bookmarkId, bookmark);

    if (!_cachedPostsBox.containsKey(postId)) {
      await _fetchAndCachePostById(postId);
    }
  }

  Future<void> syncBookmarks() async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('syncBookmarks skipped: missing current user.');
      return;
    }

    // 🚨 FIX: Routed through testable getter
    try {
      final rows = await _supabase
          .from('bookmarks')
          .select('bookmark_id, post_id, user_id')
          .eq('user_id', userId);

      final remoteBookmarks = <LocalBookmark>[];
      final bookmarkedPostIds = <String>[];

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final bookmarkId = (map['bookmark_id'] ?? '').toString();
        final bPostId = (map['post_id'] ?? '').toString();
        final bookmarkUserId = (map['user_id'] ?? '').toString();

        if (bookmarkId.isEmpty || bPostId.isEmpty || bookmarkUserId.isEmpty) {
          continue;
        }

        remoteBookmarks.add(
          LocalBookmark(
            bookmarkId: bookmarkId,
            postId: bPostId,
            userId: bookmarkUserId,
            isSynced: true,
          ),
        );
        bookmarkedPostIds.add(bPostId);
      }

      final localKeysToRemove = _bookmarkBox.keys
          .where((key) {
            final value = _bookmarkBox.get(key);
            return value != null && value.userId == userId;
          })
          .toList(growable: false);

      for (final key in localKeysToRemove) {
        await _bookmarkBox.delete(key);
      }
      for (final bookmark in remoteBookmarks) {
        await _bookmarkBox.put(bookmark.bookmarkId, bookmark);
      }

      await _fetchAndCachePostsByIds(bookmarkedPostIds);
    } catch (e) {
      debugPrint('Failed to sync bookmarks: $e');
    }
  }

  // ─── Votes ──────────────────────────────────────────────────────────────────

  Future<void> castVote({
    required String postId,
    required bool isUpvoteTarget,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Guests cannot vote. Please sign in first.');
    }

    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) throw ArgumentError('postId cannot be empty.');

    final existingLocalVote = _voteBox.values.cast<LocalVote?>().firstWhere(
      (vote) =>
          vote != null && vote.userId == userId && vote.postId == trimmedPostId,
      orElse: () => null,
    );

    // Case A: same vote again → retract
    if (existingLocalVote != null &&
        existingLocalVote.upvoteStatus == isUpvoteTarget) {
      try {
        // 🚨 FIX: Routed through testable getter
        await _supabase
            .from('votes')
            .delete()
            .eq('vote_id', existingLocalVote.voteId);
      } catch (_) {
        await _supabase
            .from('votes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', trimmedPostId);
      }
      await _voteBox.delete(existingLocalVote.voteId);
      await refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
      return;
    }

    // Case B: no prior vote → insert
    if (existingLocalVote == null) {
      String voteId = _uuid.v4();
      try {
        // 🚨 FIX: Routed through testable getter
        final inserted = await _supabase
            .from('votes')
            .insert({
              'post_id': trimmedPostId,
              'user_id': userId,
              'upvote_status': isUpvoteTarget,
            })
            .select('vote_id')
            .maybeSingle();

        if (inserted != null) {
          final map = Map<String, dynamic>.from(inserted as Map);
          final insertedVoteId = map['vote_id']?.toString();
          if (insertedVoteId != null && insertedVoteId.isNotEmpty) {
            voteId = insertedVoteId;
          }
        }
      } catch (e) {
        debugPrint('Failed to insert vote for $trimmedPostId: $e');
        rethrow;
      }

      final newLocalVote = LocalVote(
        voteId: voteId,
        postId: trimmedPostId,
        userId: userId,
        upvoteStatus: isUpvoteTarget,
        isSynced: true,
      );
      await _voteBox.put(newLocalVote.voteId, newLocalVote);
      await refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
      return;
    }

    // Case C: switch vote target → update
    try {
      // 🚨 FIX: Routed through testable getter
      await _supabase
          .from('votes')
          .update({'upvote_status': isUpvoteTarget})
          .eq('vote_id', existingLocalVote.voteId);
    } catch (_) {
      await _supabase
          .from('votes')
          .update({'upvote_status': isUpvoteTarget})
          .eq('user_id', userId)
          .eq('post_id', trimmedPostId);
    }

    existingLocalVote.upvoteStatus = isUpvoteTarget;
    existingLocalVote.isSynced = true;
    await _voteBox.put(existingLocalVote.voteId, existingLocalVote);
    await refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
  }

  Future<void> refreshCachedPostVoteState({
    required String postId,
    required String userId,
  }) async {
    final cachedPost = _cachedPostsBox.get(postId);
    if (cachedPost == null) return;

    int upvoteCount;
    try {
      // 🚨 FIX: Routed through testable getter
      final count = await _supabase
          .from('votes')
          .count(CountOption.exact)
          .eq('post_id', postId)
          .eq('upvote_status', true);
      upvoteCount = count;
    } catch (e) {
      debugPrint('Failed to fetch remote upvote count for $postId: $e');
      upvoteCount = _voteBox.values
          .where((vote) => vote.postId == postId && vote.upvoteStatus)
          .length;
    }

    final localUserVote = _voteBox.values.cast<LocalVote?>().firstWhere(
      (vote) => vote != null && vote.userId == userId && vote.postId == postId,
      orElse: () => null,
    );

    int commentCount = 0;
    try {
      // 🚨 FIX: Routed through testable getter
      final cCount = await _supabase
          .from('comments')
          .count(CountOption.exact)
          .eq('post_id', postId);
      commentCount = cCount;
    } catch (e) {
      debugPrint('Failed to fetch remote comment count for $postId: $e');
    }

    final data = Map<String, dynamic>.from(
      jsonDecode(cachedPost.cachedData) as Map,
    );
    final existingHashtags = data['hashtags'] as List?;
    if (existingHashtags == null || existingHashtags.isEmpty) {
      // Re-fetch the full post so hashtags get populated properly
      await _fetchAndCachePostById(postId);
      // Then re-read the freshly cached post and patch it
      final freshPost = _cachedPostsBox.get(postId);
      if (freshPost == null) return;
      final freshData = Map<String, dynamic>.from(
        jsonDecode(freshPost.cachedData) as Map,
      );
      freshData['upvote_count'] = upvoteCount;
      freshData['comment_count'] = commentCount;
      freshData['is_upvoted_by_me'] = localUserVote?.upvoteStatus == true;
      freshData['is_downvoted_by_me'] = localUserVote?.upvoteStatus == false;
      freshPost.cachedData = jsonEncode(freshData);
      freshPost.cachedAt = DateTime.now();
      await _cachedPostsBox.put(postId, freshPost);
      return;
    }
    data['upvote_count'] = upvoteCount;
    data['comment_count'] = commentCount;
    data['is_upvoted_by_me'] = localUserVote?.upvoteStatus == true;
    data['is_downvoted_by_me'] = localUserVote?.upvoteStatus == false;

    cachedPost.cachedData = jsonEncode(data);
    cachedPost.cachedAt = DateTime.now();
    await _cachedPostsBox.put(postId, cachedPost);
  }

  List<String> _extractHashtags(Map<String, dynamic> map) {
    final postHashtags = map['hashtags'] as List<dynamic>?;
    if (postHashtags == null || postHashtags.isEmpty) {
      return <String>[];
    }
    // This assumes your select query is: hashtags:post_hashtags(hashtags(name))
    return postHashtags
        .map((ph) => ph['hashtags']['name'].toString())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }
}
