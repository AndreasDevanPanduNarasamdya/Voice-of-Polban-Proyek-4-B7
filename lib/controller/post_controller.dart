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
  static const String _pendingPostsBoxName = 'pending_post_box'; // Added for Editors
  static const String _queueBoxName = 'sync_queue_box';

  final Uuid _uuid = const Uuid();

  Box<LocalDraft> get _draftBox => Hive.box<LocalDraft>(_draftBoxName);
  Box<CachedPost> get _cachedPostsBox => Hive.box<CachedPost>(_cachedPostsBoxName);
  Box<CachedPost> get _pendingPostsBox => Hive.box<CachedPost>(_pendingPostsBoxName);
  Box<SyncQueue> get _queueBox => Hive.box<SyncQueue>(_queueBoxName);

  // ─────────────────────────────────────────────
  // PROCESS SYNC QUEUE (The Background Engine)
  // ─────────────────────────────────────────────
  Future<void> processSyncQueue() async {
    final pendingTasks = _queueBox.values.where((task) => !task.isProcessed).toList();

    if (pendingTasks.isEmpty) return;

    final supabase = Supabase.instance.client;

    for (final task in pendingTasks) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(task.payload));

        if (task.actionType == 'UPLOAD_DRAFT') {
          // Upsert handles both insert and update automatically in 1 line
          await supabase.from('posts').upsert({
            'post_id': payload['postId'],
            'title': payload['title'],
            'content': payload['content'],
            'author_id': payload['userId'],
            'status': payload['status'],
            'created_at': payload['updatedAt'],
          });
        } else if (task.actionType == 'UPDATE_STATUS') {
          await supabase.from('posts')
              .update({'status': payload['status']})
              .eq('post_id', payload['postId']);
        }

        task.isProcessed = true;
        await _queueBox.put(task.queueId, task);
        debugPrint('Successfully synced offline task: ${task.actionType}');
        
      } catch (e) {
        debugPrint('Sync failed for task ${task.queueId}, stopping queue: $e');
        break; // Stop loop if internet drops to maintain order
      }
    }
  }

  // ─────────────────────────────────────────────
  // WRITER LOGIC
  // ─────────────────────────────────────────────
  
  // 100% Offline Draft Saving (Saves cloud bandwidth)
  Future<LocalDraft> saveDraft(String? title, String? content, String userId) async {
    final trimmedTitle = (title?.trim().isNotEmpty ?? false) ? title!.trim() : 'Draft';
    final trimmedContent = (content?.trim().isNotEmpty ?? false) ? content!.trim() : '';
    
    final newId = _uuid.v4();
    final draft = LocalDraft(
      localId: newId,
      postId: newId,
      userId: userId,
      title: trimmedTitle,
      content: trimmedContent,
      status: PostStatus.draft,
      updatedAt: DateTime.now(),
    );

    await _draftBox.put(draft.localId, draft);
    return draft;
  }

  Future<SyncQueue?> submitDraft(String localId) async {
    final draft = _draftBox.get(localId);
    if (draft == null) return null;

    final supabase = Supabase.instance.client;
    draft.status = PostStatus.pending;
    draft.updatedAt = DateTime.now();

    try {
      // 1. Try directly pushing to cloud via Upsert
      await supabase.from('posts').upsert({
        'post_id': draft.postId,
        'title': draft.title,
        'content': draft.content,
        'author_id': draft.userId,
        'status': draft.status.name,
        'created_at': draft.updatedAt.toIso8601String(),
      });
      
      await _draftBox.put(localId, draft);
      debugPrint('Draft submitted to cloud directly.');
      return null;

    } catch (e) {
      // 2. If offline, push to Sync Queue
      debugPrint('Offline mode: Pushing draft submission to Sync Queue.');
      await _draftBox.put(localId, draft); // Update status locally

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

  // ─────────────────────────────────────────────
  // READER LOGIC
  // ─────────────────────────────────────────────
  Future<List<CachedPost>> fetchFeed() async {
    try {
      final rows = await Supabase.instance.client
          .from('posts')
          .select('post_id, title, content, author_id, status, created_at')
          .eq('status', PostStatus.published.name)
          .order('created_at', ascending: false)
          .limit(8); // Strict limit to 8 posts!

      await _cachedPostsBox.clear(); // Empty old cache to maintain size 8

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        if (postId.isEmpty) continue;

        final cachedData = jsonEncode({
          'title': (map['title'] ?? '').toString(),
          'content': (map['content'] ?? '').toString(),
          'author_id': map['author_id'],
        });

        final cp = CachedPost(
          postId: postId,
          cachedData: cachedData,
          cachedAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
        );
        posts.add(cp);
        await _cachedPostsBox.put(postId, cp);
      }
      return posts;
      
    } catch (e) {
      debugPrint('Offline: Falling back to 8 cached posts. Error: $e');
      return getOfflinePosts();
    }
  }

  // ─────────────────────────────────────────────
  // EDITOR LOGIC
  // ─────────────────────────────────────────────
  Future<List<CachedPost>> fetchPendingPosts() async {
    try {
      final rows = await Supabase.instance.client
          .from('posts')
          .select('post_id, title, content, author_id, status, created_at')
          .eq('status', PostStatus.pending.name)
          .order('created_at', ascending: false);

      await _pendingPostsBox.clear(); // Clear old pending posts

      final List<CachedPost> pendingPosts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        if (postId.isEmpty) continue;

        final cp = CachedPost(
          postId: postId,
          cachedData: jsonEncode({
            'title': (map['title'] ?? '').toString(),
            'content': (map['content'] ?? '').toString(),
            'author_id': map['author_id'],
            'status': PostStatus.pending.name,
          }),
          cachedAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
        );
        pendingPosts.add(cp);
        await _pendingPostsBox.put(postId, cp);
      }
      return pendingPosts;

    } catch (e) {
      debugPrint('Offline: Reading pending posts from cache.');
      return _pendingPostsBox.values.toList();
    }
  }

  Future<bool> _updatePostStatus(String postId, PostStatus newStatus) async {
    try {
      // 1. Try updating cloud directly
      await Supabase.instance.client
          .from('posts')
          .update({'status': newStatus.name})
          .eq('post_id', postId);
          
      // Clean up Editor's local view
      await _pendingPostsBox.delete(postId); 
      
      // If it was published, we could technically update the reader feed box here,
      // but the 2-minute sync loop will fetch it anyway.
      return true;

    } catch (e) {
      // 2. If offline, save to queue
      debugPrint('Offline mode: Pushing Editor action to Sync Queue.');
      
      final task = SyncQueue(
        queueId: _uuid.v4(),
        actionType: 'UPDATE_STATUS',
        payload: jsonEncode({'postId': postId, 'status': newStatus.name}),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      await _queueBox.put(task.queueId, task);
      await _pendingPostsBox.delete(postId); // Remove locally so Editor thinks it worked
      return true;
    }
  }

  Future<bool> approvePost(String postId) async {
    return await _updatePostStatus(postId, PostStatus.published);
  }

  Future<bool> rejectPost(String postId) async {
    return await _updatePostStatus(postId, PostStatus.rejected);
  }

  // ─────────────────────────────────────────────
  // HELPERS (RESTORED FROM ORIGINAL FILE)
  // ─────────────────────────────────────────────
  List<CachedPost> getOfflinePosts() {
    final posts = _cachedPostsBox.values.toList(growable: false);
    // Sort so newest is on top even offline
    posts.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
    return posts;
  }

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  LocalDraft? getDraftById(String localId) => _draftBox.get(localId);
}