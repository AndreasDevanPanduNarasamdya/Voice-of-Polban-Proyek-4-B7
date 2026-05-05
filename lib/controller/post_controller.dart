import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_enums.dart';
import '../models/cached_post.dart';
import '../models/local_draft.dart';
import '../models/sync_queue.dart';

class PostController {
  static const String _draftBoxName = 'local_draft_box';
  static const String _cachedPostsBoxName = 'cached_post_box';
  static const String _queueBoxName = 'sync_queue_box';

  final Uuid _uuid = const Uuid();

  Box<LocalDraft> get _draftBox => Hive.box<LocalDraft>(_draftBoxName);
  Box<CachedPost> get _cachedPostsBox =>
      Hive.box<CachedPost>(_cachedPostsBoxName);
  Box<SyncQueue> get _queueBox => Hive.box<SyncQueue>(_queueBoxName);

  Future<LocalDraft> saveDraft(
    String? title,
    String? content,
    String userId,
  ) async {
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
      );

      await _draftBox.put(draft.localId, draft);
      return draft;
    }
  }

  Future<SyncQueue?> submitDraft(String localId) async {
    final draft = _draftBox.get(localId);
    if (draft == null) {
      return null;
    }

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

  /// Fetch published posts from Supabase, update local cache, and return them.
  Future<List<CachedPost>> fetchFeed() async {
    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          .select('post_id, title, content, author_id, status, created_at')
          .eq('status', PostStatus.published.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        final title = (map['title'] ?? '').toString();
        final content = (map['content'] ?? '').toString();
        final createdAtRaw = map['created_at'];
        DateTime createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
        } else if (createdAtRaw is DateTime) {
          createdAt = createdAtRaw;
        } else {
          createdAt = DateTime.now();
        }

        final cachedData = jsonEncode({
          'title': title,
          'content': content,
          'author_id': map['author_id'],
        });

        if (postId.isEmpty) continue;

        final cachedPost = CachedPost(
          postId: postId,
          cachedData: cachedData,
          cachedAt: createdAt,
        );
        await _cachedPostsBox.put(postId, cachedPost);
        posts.add(cachedPost);
      }

      return posts;
    } catch (e) {
      debugPrint('Failed to fetch feed from Supabase: $e');
      return getOfflinePosts();
    }
  }

  Future<List<CachedPost>> fetchPendingPosts() async {
    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          .select('post_id, title, content, author_id, status, created_at')
          .eq('status', PostStatus.pending.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        if (postId.isEmpty) continue;

        final cachedPost = CachedPost(
          postId: postId,
          cachedData: jsonEncode({
            'title': (map['title'] ?? '').toString(),
            'content': (map['content'] ?? '').toString(),
            'author_id': map['author_id'],
            'status': PostStatus.pending.name,
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

  Future<bool> approvePost(String postId) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'status': PostStatus.published.name})
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

  Future<bool> rejectPost(String postId) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'status': PostStatus.rejected.name})
          .eq('post_id', postId);

      final cachedPost = _cachedPostsBox.get(postId);
      if (cachedPost != null) {
        final data = Map<String, dynamic>.from(
          jsonDecode(cachedPost.cachedData) as Map,
        );
        data['status'] = PostStatus.rejected.name;
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

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  LocalDraft? getDraftById(String localId) => _draftBox.get(localId);
}
