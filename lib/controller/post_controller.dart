import 'dart:convert';
import 'dart:io';
import '../models/cached_user.dart'; // <--- ADD THIS
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_enums.dart';
import '../models/cached_post.dart';
import '../models/comment_model.dart';
import '../models/local_bookmark.dart';
import '../models/local_vote.dart';
import '../models/local_draft.dart';
import '../models/sync_queue.dart';

class PostController {
  static const String _draftBoxName = 'local_draft_box';
  static const String _cachedPostsBoxName = 'cached_post_box';
  static const String _bookmarkBoxName = 'local_bookmark_box';
  static const String _voteBoxName = 'local_vote_box';
  static const String _queueBoxName = 'sync_queue_box';

  final Uuid _uuid = const Uuid();

  Box<LocalDraft> get _draftBox => Hive.box<LocalDraft>(_draftBoxName);
  Box<CachedPost> get _cachedPostsBox =>
      Hive.box<CachedPost>(_cachedPostsBoxName);
  Box<LocalBookmark> get _bookmarkBox =>
      Hive.box<LocalBookmark>(_bookmarkBoxName);
  Box<LocalVote> get _voteBox => Hive.box<LocalVote>(_voteBoxName);
  Box<SyncQueue> get _queueBox => Hive.box<SyncQueue>(_queueBoxName);

  String? get _currentUserId {
    // Prefer the local session stored by AuthController in Hive ('session_box').
    // This avoids mismatch between local session and Supabase client auth.
    try {
      final sessionBox = Hive.box('session_box');
      final userId = sessionBox.get('logged_in_user_id');
      if (userId == null) {
        // Fallback to Supabase auth if no local session available.
        return Supabase.instance.client.auth.currentUser?.id;
      }
      return userId.toString();
    } catch (_) {
      // If Hive isn't ready or box missing, fallback to Supabase auth.
      return Supabase.instance.client.auth.currentUser?.id;
    }
  }

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
        'status': (map['status'] ?? PostStatus.published.name).toString(),
        if (map['rejection_note'] != null)
          'rejection_note': map['rejection_note'].toString(),
      }),
      cachedAt: _parsePostDate(map['created_at']),
    );
  }

  Future<CachedPost?> _fetchAndCachePostById(String postId) async {
    if (postId.trim().isEmpty) {
      return null;
    }

    final supabase = Supabase.instance.client;
    try {
      final row = await supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, rejection_note, attachments(attachment_details(file_path))',
          )
          .eq('post_id', postId)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      final map = Map<String, dynamic>.from(row as Map);
      final cachedPost = _buildCachedPost(map);
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

    if (uniquePostIds.isEmpty) {
      return <CachedPost>[];
    }

    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, rejection_note, attachments(attachment_details(file_path))',
          )
          .inFilter('post_id', uniquePostIds);

      final List<CachedPost> cachedPosts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final cachedPost = _buildCachedPost(map);
        if (cachedPost == null) {
          continue;
        }
        await _cachedPostsBox.put(cachedPost.postId, cachedPost);
        cachedPosts.add(cachedPost);
      }
      return cachedPosts;
    } catch (e) {
      debugPrint('Failed to fetch/cache bookmarked posts: $e');
      return <CachedPost>[];
    }
  }

  Future<LocalDraft> saveDraft(
    String? title,
    String? content,
    String userId, {
    List<String>? imageUrls,
  }) async {
    final trimmedTitle = (title?.trim().isNotEmpty ?? false)
        ? title!.trim()
        : 'Dummy Title from Debug';
    final trimmedContent = (content?.trim().isNotEmpty ?? false)
        ? content!.trim()
        : 'Dummy Content';
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('posts')
          .insert({
            'title': trimmedTitle,
            'content': trimmedContent,
            'author_id': userId,
            'status': PostStatus.draft.name,
          })
          .select('post_id')
          .single();

      debugPrint('Supabase post insert response: $response');

      final responseMap = Map<String, dynamic>.from(response as Map);
      final idValue = responseMap['post_id'];
      if (idValue == null) {
        throw StateError('Supabase returned no id for inserted post.');
      }

      final supabasePostId = idValue.toString();
      final draft = LocalDraft(
        localId: supabasePostId,
        postId: supabasePostId,
        userId: userId,
        title: trimmedTitle,
        content: trimmedContent,
        status: PostStatus.draft,
        updatedAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _draftBox.put(draft.localId, draft);
      return draft;
    } catch (e) {
      debugPrint(
        'Supabase post insert failed: $e. Falling back to local save.',
      );

      final draft = LocalDraft(
        localId: _uuid.v4(),
        postId: _uuid.v4(),
        userId: userId,
        title: trimmedTitle,
        content: trimmedContent,
        status: PostStatus.draft,
        updatedAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _draftBox.put(draft.localId, draft);
      return draft;
    }
  }

  // --- ADD THIS METHOD INSIDE PostController ---
  Future<void> syncMyArticles(String userId) async {
    final supabase = Supabase.instance.client;
    try {
      // Fetch all posts authored by this user from the cloud
      final rows = await supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, rejection_note, attachments(attachment_details(file_path))',
          )
          .eq('author_id', userId);

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? '').toString();
        if (postId.isEmpty) continue;

        // Parse status safely
        PostStatus status = PostStatus.draft;
        try {
          if (map['status'] != null) {
            status = PostStatus.values.byName(
              map['status'].toString().toLowerCase(),
            );
          }
        } catch (_) {}

        // Extract images
        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details =
              attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final updatedAt =
            DateTime.tryParse((map['created_at'] ?? '').toString()) ??
            DateTime.now();

        // Overwrite the local Hive cache with the true Cloud data
        final draft = LocalDraft(
          localId: postId,
          postId: postId,
          userId: userId,
          title: (map['title'] ?? '').toString(),
          content: (map['content'] ?? '').toString(),
          status: status,
          updatedAt: updatedAt,
          rejectionNote: map['rejection_note']?.toString(),
          imageUrls: imageUrls.isEmpty ? null : imageUrls,
        );

        await _draftBox.put(draft.localId, draft);
      }
    } catch (e) {
      debugPrint('Failed to sync user articles from Supabase: $e');
    }
  }

  Future<List<String>> _uploadImages(List<String>? paths, String postId) async {
    if (paths == null || paths.isEmpty) return [];

    final supabase = Supabase.instance.client;
    List<String> uploadedUrls = [];

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (path.startsWith('http')) {
        uploadedUrls.add(path);
        continue;
      }
      try {
        final file = File(path);
        final fileExt = path.split('.').last;
        final fileName =
            '${postId}_${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';

        // Make sure both of these say 'post_attachments'
        await supabase.storage.from('post_attachments').upload(fileName, file);
        final publicUrl = supabase.storage
            .from('post_attachments')
            .getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      } catch (e) {
        debugPrint('Failed to upload image $path: $e');
      }
    }
    return uploadedUrls;
  }

  Future<SyncQueue?> submitDraft(String localId) async {
    final draft = _draftBox.get(localId);
    if (draft == null) {
      return null;
    }

    final finalUrls = await _uploadImages(draft.imageUrls, draft.postId);
    draft.imageUrls = finalUrls;

    final supabase = Supabase.instance.client;

    try {
      // Check if this post already exists in Supabase
      final existingPost = await supabase
          .from('posts')
          .select()
          .eq('post_id', draft.postId)
          .maybeSingle();

      if (existingPost != null) {
        // Update existing post's status
        debugPrint('Updating existing Supabase post: ${draft.postId}');
        await supabase
            .from('posts')
            .update({'status': PostStatus.pending.name})
            .eq('post_id', draft.postId);
      } else {
        // Insert new post since it doesn't exist in Supabase
        debugPrint('Inserting new Supabase post from draft: ${draft.postId}');
        await supabase
            .from('posts')
            .insert({
              'post_id': draft.postId,
              'title': draft.title,
              'content': draft.content,
              'author_id': draft.userId,
              'status': PostStatus.pending.name,
            })
            .select('post_id')
            .single();
      }

      // ADDED THIS: The relational attachments logic
      if (finalUrls.isNotEmpty) {
        final existingAttachment = await supabase
            .from('attachments')
            .select('attachment_id')
            .eq('post_id', draft.postId)
            .maybeSingle();
        String attachmentId;

        if (existingAttachment != null) {
          attachmentId = existingAttachment['attachment_id'];
          await supabase
              .from('attachment_details')
              .delete()
              .eq('attachment_id', attachmentId);
        } else {
          final newAttachment = await supabase
              .from('attachments')
              .insert({'type': 'image', 'post_id': draft.postId})
              .select('attachment_id')
              .single();
          attachmentId = newAttachment['attachment_id'];
        }

        final attachmentDetailsRows = finalUrls
            .asMap()
            .entries
            .map(
              (entry) => {
                'attachment_id': attachmentId,
                'attachment_order': entry.key,
                'file_path': entry.value,
              },
            )
            .toList();

        await supabase.from('attachment_details').insert(attachmentDetailsRows);
      }

      // Update local draft status
      draft.status = PostStatus.pending;
      draft.updatedAt = DateTime.now();
      await _draftBox.put(localId, draft);

      // Create sync queue entry
      final queueEntry = SyncQueue(
        queueId: _uuid.v4(),
        actionType: 'UPLOAD_DRAFT',
        payload: jsonEncode({
          'localId': draft.localId,
          'postId': draft.postId,
          'userId': draft.userId,
          'title': draft.title,
          'content': draft.content,
          'status': draft.status.name,
          'imageUrls': finalUrls,
          'updatedAt': draft.updatedAt.toIso8601String(),
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      await _queueBox.put(queueEntry.queueId, queueEntry);
      return queueEntry;
    } catch (e) {
      debugPrint(
        'Supabase post submission failed: $e. Falling back to local queue.',
      );

      // Fallback: update local state and queue it
      draft.status = PostStatus.pending;
      draft.updatedAt = DateTime.now();
      await _draftBox.put(localId, draft);

      final queueEntry = SyncQueue(
        queueId: _uuid.v4(),
        actionType: 'UPLOAD_DRAFT',
        payload: jsonEncode({
          'localId': draft.localId,
          'postId': draft.postId,
          'userId': draft.userId,
          'title': draft.title,
          'content': draft.content,
          'status': draft.status.name,
          'imageUrls': draft.imageUrls,
          'updatedAt': draft.updatedAt.toIso8601String(),
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      await _queueBox.put(queueEntry.queueId, queueEntry);
      return queueEntry;
    }
  }

  List<CachedPost> getOfflinePosts() {
    return _cachedPostsBox.values.toList(growable: false);
  }

  Future<void> toggleBookmark(String postId) async {
    final userId = _currentUserId;
    if (userId == null || postId.trim().isEmpty) {
      debugPrint('toggleBookmark skipped: missing user or post id.');
      return;
    }

    final existingEntry = _bookmarkBox.values.cast<LocalBookmark?>().firstWhere(
      (bookmark) =>
          bookmark != null &&
          bookmark.userId == userId &&
          bookmark.postId == postId,
      orElse: () => null,
    );

    final supabase = Supabase.instance.client;

    if (existingEntry != null) {
      try {
        await supabase
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
      final inserted = await supabase
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

    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('bookmarks')
          .select('bookmark_id, post_id, user_id')
          .eq('user_id', userId);

      final remoteBookmarks = <LocalBookmark>[];
      final bookmarkedPostIds = <String>[];

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final bookmarkId = (map['bookmark_id'] ?? '').toString();
        final postId = (map['post_id'] ?? '').toString();
        final bookmarkUserId = (map['user_id'] ?? '').toString();

        if (bookmarkId.isEmpty || postId.isEmpty || bookmarkUserId.isEmpty) {
          continue;
        }

        remoteBookmarks.add(
          LocalBookmark(
            bookmarkId: bookmarkId,
            postId: postId,
            userId: bookmarkUserId,
            isSynced: true,
          ),
        );
        bookmarkedPostIds.add(postId);
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

  Future<List<CommentModel>> fetchComments(String postId) async {
    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      return <CommentModel>[];
    }

    try {
      final rows = await Supabase.instance.client
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
    if (trimmedPostId.isEmpty) {
      throw ArgumentError('postId cannot be empty.');
    }
    if (trimmedContent.isEmpty) {
      throw ArgumentError('content cannot be empty.');
    }

    await Supabase.instance.client.from('comments').insert({
      'post_id': trimmedPostId,
      'user_id': userId,
      'content': trimmedContent,
    });

    final cachedPost = _cachedPostsBox.get(trimmedPostId);
    if (cachedPost != null) {
      final data = Map<String, dynamic>.from(jsonDecode(cachedPost.cachedData) as Map);
      final currentCount = data['comment_count'] ?? 0;
      data['comment_count'] = (currentCount is num ? currentCount.toInt() : int.tryParse(currentCount.toString()) ?? 0) + 1;
      cachedPost.cachedData = jsonEncode(data);
      cachedPost.cachedAt = DateTime.now();
      await _cachedPostsBox.put(trimmedPostId, cachedPost);
    }
  }

  Future<void> castVote({
    required String postId,
    required bool isUpvoteTarget,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Guests cannot vote. Please sign in first.');
    }

    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      throw ArgumentError('postId cannot be empty.');
    }

    LocalVote? existingLocalVote = _voteBox.values
        .cast<LocalVote?>()
        .firstWhere(
          (vote) =>
              vote != null &&
              vote.userId == userId &&
              vote.postId == trimmedPostId,
          orElse: () => null,
        );

    final supabase = Supabase.instance.client;

    if (existingLocalVote == null) {
      try {
        final remoteVote = await supabase
            .from('votes')
            .select('vote_id, upvote_status')
            .eq('post_id', trimmedPostId)
            .eq('user_id', userId)
            .maybeSingle();

        if (remoteVote != null) {
          // Ternyata di server sudah ada! Kita tarik dan simpan ke memori lokal
          existingLocalVote = LocalVote(
            voteId: remoteVote['vote_id'].toString(),
            postId: trimmedPostId,
            userId: userId,
            upvoteStatus: remoteVote['upvote_status'] == true,
            isSynced: true,
          );
          await _voteBox.put(existingLocalVote.voteId, existingLocalVote);
        }
      } catch (e) {
        debugPrint('Gagal mengecek histori vote di server: $e');
      }
    }

    // Case A: click the same vote again -> retract vote.
    if (existingLocalVote != null &&
        existingLocalVote.upvoteStatus == isUpvoteTarget) {
      try {
        await supabase
            .from('votes')
            .delete()
            .eq('vote_id', existingLocalVote.voteId);
      } catch (_) {
        // Fallback for stale local vote_id.
        await supabase
            .from('votes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', trimmedPostId);
      }

      await _voteBox.delete(existingLocalVote.voteId);
      await _refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
      return;
    }

    // Case B: no prior vote -> insert fresh row.
    if (existingLocalVote == null) {
      String voteId = _uuid.v4();
      try {
        final inserted = await supabase
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
      await _refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
      return;
    }

    // Case C: switch vote target -> update existing row.
    try {
      await supabase
          .from('votes')
          .update({'upvote_status': isUpvoteTarget})
          .eq('vote_id', existingLocalVote.voteId);
    } catch (_) {
      // Fallback for stale local vote_id.
      await supabase
          .from('votes')
          .update({'upvote_status': isUpvoteTarget})
          .eq('user_id', userId)
          .eq('post_id', trimmedPostId);
    }

    existingLocalVote.upvoteStatus = isUpvoteTarget;
    existingLocalVote.isSynced = true;
    await _voteBox.put(existingLocalVote.voteId, existingLocalVote);

    await _refreshCachedPostVoteState(postId: trimmedPostId, userId: userId);
  }

  Future<void> _refreshCachedPostVoteState({
    required String postId,
    required String userId,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // 1. Ambil total upvote dari server secara real-time
      final upvotesResponse = await supabase
          .from('votes')
          .select('vote_id')
          .eq('post_id', postId)
          .eq('upvote_status', true);

      final totalUpvotes = (upvotesResponse as List).length;

      // 2. Cek status vote khusus untuk user yang sedang login saat ini
      bool isUpvotedByMe = false;
      bool isDownvotedByMe = false;

      if (userId.isNotEmpty) {
        final myVote = await supabase
            .from('votes')
            .select('upvote_status')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();

        if (myVote != null) {
          if (myVote['upvote_status'] == true) {
            isUpvotedByMe = true;
          } else {
            isDownvotedByMe = true;
          }
        }
      }

      // 3. Simpan data terbaru ke memori lokal (Hive) agar UI otomatis merespons
      final postBox = Hive.box<CachedPost>('cached_post_box');
      final existingPost = postBox.get(postId);

      if (existingPost != null) {
        // Buka JSON lama
        final parsed =
            jsonDecode(existingPost.cachedData) as Map<String, dynamic>;

        // Perbarui nilainya
        parsed['upvote_count'] = totalUpvotes;
        parsed['is_upvoted_by_me'] = isUpvotedByMe;
        parsed['is_downvoted_by_me'] = isDownvotedByMe;

        // Simpan kembali JSON yang sudah diperbarui
        existingPost.cachedData = jsonEncode(parsed);
        await postBox.put(postId, existingPost);
      }
    } catch (e) {
      debugPrint('Gagal melakukan sinkronisasi state vote: $e');
    }
  }

  List<CachedPost> getOfflineBookmarks() {
    final userId = _currentUserId;
    if (userId == null) {
      return <CachedPost>[];
    }

    final bookmarkedPostIds = _bookmarkBox.values
        .where((bookmark) => bookmark.userId == userId)
        .map((bookmark) => bookmark.postId)
        .toSet();

    if (bookmarkedPostIds.isEmpty) {
      return <CachedPost>[];
    }

    return bookmarkedPostIds
        .map(_cachedPostsBox.get)
        .whereType<CachedPost>()
        .toList(growable: false);
  }

  Future<List<CachedPost>> fetchFeed() async {
    final supabase = Supabase.instance.client;
    try {
      // 1. Fetch Posts Only (Removes the dangerous users(...) join)
      final rows = await supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, attachments(attachment_details(file_path))',
          )
          .eq('status', PostStatus.published.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      final usersBox = Hive.box<CachedUser>('cached_user_box');

      // 2. Fetch Authors Independently
      final authorIds = rows
          .map((r) => (r as Map)['author_id'].toString())
          .toSet()
          .toList();
      if (authorIds.isNotEmpty) {
        try {
          final userRows = await supabase
              .from('users')
              .select('user_id, name, avatar_url, role')
              .inFilter('user_id', authorIds);
          for (final u in userRows as List) {
            final umap = Map<String, dynamic>.from(u as Map);
            final uid = umap['user_id'].toString();
            UserRole urole = UserRole.reader;
            try {
              urole = UserRole.values.byName(
                umap['role'].toString().toLowerCase(),
              );
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

      // 3. Process the Posts
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? '').toString();
        if (postId.isEmpty) continue;

        final createdAtRaw = map['created_at'];
        DateTime createdAt = (createdAtRaw is String)
            ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
            : DateTime.now();

        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details =
              attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final existingPost = _cachedPostsBox.get(
          postId,
        ); // 👈 get old entry first
        final existingParsed = existingPost != null
            ? jsonDecode(existingPost.cachedData) as Map<String, dynamic>
            : <String, dynamic>{};

        final cachedData = jsonEncode({
          'title': (map['title'] ?? '').toString(),
          'content': (map['content'] ?? '').toString(),
          'author_id': map['author_id']?.toString() ?? '',
          'imageUrls': imageUrls,
          'status': PostStatus.published.name,
          'upvote_count': existingParsed['upvote_count'] ?? 0,
          'is_upvoted_by_me': existingParsed['is_upvoted_by_me'] ?? false,
          'is_downvoted_by_me': existingParsed['is_downvoted_by_me'] ?? false,
        });

        final cachedPost = CachedPost(
          postId: postId,
          cachedData: cachedData,
          cachedAt: createdAt,
        );
        await _cachedPostsBox.put(postId, cachedPost);
        posts.add(cachedPost);
      }
      final userId = _currentUserId ?? '';
      for (final post in posts) {
        await _refreshCachedPostVoteState(postId: post.postId, userId: userId);
      }
      return posts;
    } catch (e) {
      debugPrint('Failed to fetch feed from Supabase: $e');
      return getOfflinePosts();
    }
  }

  /// Fetch published posts from Supabase, update local cache, and return them.
  Future<List<CachedPost>> fetchPendingPosts() async {
    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          .select(
            'post_id, title, content, author_id, status, created_at, attachments(attachment_details(file_path))',
          )
          .eq('status', PostStatus.pending.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      final usersBox = Hive.box<CachedUser>('cached_user_box');

      // Fetch Authors Independently
      final authorIds = rows
          .map((r) => (r as Map)['author_id'].toString())
          .toSet()
          .toList();
      if (authorIds.isNotEmpty) {
        try {
          final userRows = await supabase
              .from('users')
              .select('user_id, name, avatar_url, role')
              .inFilter('user_id', authorIds);
          for (final u in userRows as List) {
            final umap = Map<String, dynamic>.from(u as Map);
            final uid = umap['user_id'].toString();
            await usersBox.put(
              uid,
              CachedUser(
                userId: uid,
                name: umap['name'].toString(),
                email: '',
                role: UserRole.writer,
                avatarUrl: umap['avatar_url']?.toString() ?? '',
              ),
            );
          }
        } catch (userErr) {
          debugPrint('Failed to sync authors independently: $userErr');
        }
      }

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? '').toString();
        if (postId.isEmpty) continue;

        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details =
              attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final cachedPost = CachedPost(
          postId: postId,
          cachedData: jsonEncode({
            'title': (map['title'] ?? '').toString(),
            'content': (map['content'] ?? '').toString(),
            'author_id': map['author_id']?.toString() ?? '',
            'status': PostStatus.pending.name,
            'imageUrls': imageUrls,
          }),
          cachedAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
        );

        await _cachedPostsBox.put(postId, cachedPost);
        posts.add(cachedPost);
      }
      return posts;
    } catch (e) {
      debugPrint('Failed to fetch pending posts from Supabase: $e');
      return <CachedPost>[];
    }
  }

  Future<bool> approvePost(String postId, {String note = ''}) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'status': PostStatus.published.name, 'rejection_note': note})
          .eq('post_id', postId);

      final cachedPost = _cachedPostsBox.get(postId);
      if (cachedPost != null) {
        final data = Map<String, dynamic>.from(
          jsonDecode(cachedPost.cachedData) as Map,
        );
        data['status'] = PostStatus.published.name;
        cachedPost.cachedData = jsonEncode(data);
        cachedPost.cachedAt = DateTime.now();
        await _cachedPostsBox.put(postId, cachedPost);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to approve post $postId: $e');
      return false;
    }
  }

  // Replace your existing rejectPost method with this one
  Future<bool> rejectPost(String postId, {String note = ''}) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({
            'status': PostStatus.rejected.name,
            'rejection_note': note, // Assuming you add this column to Supabase
          })
          .eq('post_id', postId);

      final cachedPost = _cachedPostsBox.get(postId);
      if (cachedPost != null) {
        final data = Map<String, dynamic>.from(
          jsonDecode(cachedPost.cachedData) as Map,
        );
        data['status'] = PostStatus.rejected.name;
        data['rejection_note'] = note;

        cachedPost.cachedData = jsonEncode(data);
        cachedPost.cachedAt = DateTime.now();
        await _cachedPostsBox.put(postId, cachedPost);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to reject post $postId: $e');
      return false;
    }
  }

  Future<bool> deleteArticle(String id) async {
    final supabase = Supabase.instance.client;

    try {
      // 1. Attempt to delete from Supabase
      await supabase.from('posts').delete().eq('post_id', id);

      // 2. Remove from Local Cache
      if (_cachedPostsBox.containsKey(id)) {
        await _cachedPostsBox.delete(id);
      }

      // 3. Remove from Local Drafts
      if (_draftBox.containsKey(id)) {
        await _draftBox.delete(id);
      }

      return true;
    } catch (e) {
      debugPrint(
        'Failed to delete article online: $e. Falling back to local offline delete.',
      );

      // Fallback: Delete locally and queue the action
      if (_cachedPostsBox.containsKey(id)) {
        await _cachedPostsBox.delete(id);
      }
      if (_draftBox.containsKey(id)) {
        await _draftBox.delete(id);
      }

      final queueEntry = SyncQueue(
        queueId: _uuid.v4(),
        actionType: 'DELETE_POST',
        payload: jsonEncode({'postId': id}),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      await _queueBox.put(queueEntry.queueId, queueEntry);
      return false;
    }
  }

  Future<LocalDraft?> updateDraft(
    String localId,
    String newTitle,
    String newContent, {
    List<String>? imageUrls,
  }) async {
    final draft = _draftBox.get(localId);
    if (draft == null) return null;

    final trimmedTitle = newTitle.trim().isNotEmpty
        ? newTitle.trim()
        : draft.title;
    final trimmedContent = newContent.trim().isNotEmpty
        ? newContent.trim()
        : draft.content;

    draft.title = trimmedTitle;
    draft.content = trimmedContent;
    draft.imageUrls = imageUrls;
    draft.updatedAt = DateTime.now();
    await _draftBox.put(localId, draft);

    // Sync to Supabase
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'title': draft.title, 'content': draft.content})
          .eq('post_id', draft.postId);
    } catch (e) {
      debugPrint('Supabase update failed: $e. Queuing update.');

      final queueEntry = SyncQueue(
        queueId: _uuid.v4(),
        actionType: 'UPDATE_DRAFT',
        payload: jsonEncode({
          'postId': draft.postId,
          'title': draft.title,
          'content': draft.content,
          'imageUrls': draft.imageUrls,
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );
      await _queueBox.put(queueEntry.queueId, queueEntry);
    }

    return draft;
  }

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  LocalDraft? getDraftById(String localId) => _draftBox.get(localId);

  // --- THE SYNC WORKER ---
  Future<void> processSyncQueue() async {
    // 1. Find all items that haven't been pushed to the server yet
    final pendingTasks = _queueBox.values
        .where((entry) => !entry.isProcessed)
        .toList();
    if (pendingTasks.isEmpty) return;

    final supabase = Supabase.instance.client;

    // 2. Process them one by one
    for (final task in pendingTasks) {
      try {
        final payload = jsonDecode(task.payload);

        if (task.actionType == 'UPLOAD_DRAFT') {
          await supabase.from('posts').upsert({
            'post_id': payload['postId'],
            'title': payload['title'],
            'content': payload['content'],
            'author_id': payload['userId'],
            'status': payload['status'],
          });
        } else if (task.actionType == 'UPDATE_DRAFT') {
          await supabase
              .from('posts')
              .update({
                'title': payload['title'],
                'content': payload['content'],
              })
              .eq('post_id', payload['postId']);
        } else if (task.actionType == 'DELETE_POST') {
          await supabase
              .from('posts')
              .delete()
              .eq('post_id', payload['postId']);
        }

        // 3. If successful, mark as processed so we don't duplicate it!
        task.isProcessed = true;
        await _queueBox.put(task.queueId, task);
        debugPrint('Successfully synced offline task: ${task.actionType}');
      } catch (e) {
        debugPrint('Sync task failed (Still Offline?): $e');
        // It failed, so we leave isProcessed as false. It will try again next time!
      }
    }
  }

  Future<void> syncLiveVoteCount(String postId) async {
    // Ambil ID user yang sedang login, jika guest berikan string kosong
    final userId = _currentUserId ?? '';

    // Panggil fungsi internal yang akan mengunduh jumlah pastinya dari database
    // dan menyimpannya kembali ke local cache (Hive) agar UI otomatis terupdate
    await _refreshCachedPostVoteState(postId: postId, userId: userId);
  }
}
