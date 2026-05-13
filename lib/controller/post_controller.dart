import 'dart:convert';
import 'dart:io';

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
    {List<String>? imageUrls}
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
        final fileName = '${postId}_${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';
        
        // Make sure both of these say 'post_attachments'
        await supabase.storage.from('post_attachments').upload(fileName, file);
        final publicUrl = supabase.storage.from('post_attachments').getPublicUrl(fileName);
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
        final existingAttachment = await supabase.from('attachments').select('attachment_id').eq('post_id', draft.postId).maybeSingle();
        String attachmentId;
        
        if (existingAttachment != null) {
          attachmentId = existingAttachment['attachment_id'];
          await supabase.from('attachment_details').delete().eq('attachment_id', attachmentId);
        } else {
          final newAttachment = await supabase.from('attachments').insert({
            'type': 'image',
            'post_id': draft.postId,
          }).select('attachment_id').single();
          attachmentId = newAttachment['attachment_id'];
        }

        final attachmentDetailsRows = finalUrls.asMap().entries.map((entry) => {
          'attachment_id': attachmentId,
          'attachment_order': entry.key,
          'file_path': entry.value,
        }).toList();

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

  /// Fetch published posts from Supabase, update local cache, and return them.
Future<List<CachedPost>> fetchFeed() async {
    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          // ADDED THE ATTACHMENTS JOIN HERE
          .select('post_id, title, content, author_id, status, created_at, attachments(attachment_details(file_path))')
          .eq('status', PostStatus.published.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        final title = (map['title'] ?? '').toString();
        final content = (map['content'] ?? '').toString();
        
        final createdAtRaw = map['created_at'];
        DateTime createdAt = (createdAtRaw is String) ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now()) : DateTime.now();

        // EXTRACT IMAGES SAFELY
        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details = attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final cachedData = jsonEncode({
          'title': title,
          'content': content,
          'author_id': map['author_id'],
          'imageUrls': imageUrls, // SAVE IMAGES TO CACHE
        });

        if (postId.isEmpty) continue;

        final cachedPost = CachedPost(postId: postId, cachedData: cachedData, cachedAt: createdAt);
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
          // ADDED THE ATTACHMENTS JOIN HERE
          .select('post_id, title, content, author_id, status, created_at, attachments(attachment_details(file_path))')
          .eq('status', PostStatus.pending.name)
          .order('created_at', ascending: false);

      final List<CachedPost> posts = [];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final postId = (map['post_id'] ?? map['id'] ?? '').toString();
        if (postId.isEmpty) continue;

        // EXTRACT IMAGES SAFELY
        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details = attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        final cachedPost = CachedPost(
          postId: postId,
          cachedData: jsonEncode({
            'title': (map['title'] ?? '').toString(),
            'content': (map['content'] ?? '').toString(),
            'author_id': map['author_id'],
            'status': PostStatus.pending.name,
            'imageUrls': imageUrls, // SAVE IMAGES TO CACHE
          }),
          cachedAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
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

// Replace your existing rejectPost method with this one
  Future<bool> rejectPost(String postId, {String note = ''}) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({
            'status': PostStatus.rejected.name,
            'rejection_note': note // Assuming you add this column to Supabase
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
      debugPrint('Failed to delete article online: $e. Falling back to local offline delete.');
      
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
    String newContent,
    {List<String>? imageUrls}
  ) async {
    final draft = _draftBox.get(localId);
    if (draft == null) return null;

    final trimmedTitle = newTitle.trim().isNotEmpty ? newTitle.trim() : draft.title;
    final trimmedContent = newContent.trim().isNotEmpty ? newContent.trim() : draft.content;
    
    draft.title = trimmedTitle;
    draft.content = trimmedContent;
    draft.imageUrls = imageUrls;
    draft.updatedAt = DateTime.now();
    await _draftBox.put(localId, draft);

    // Sync to Supabase
    try {
      await Supabase.instance.client
          .from('posts')
          .update({
            'title': draft.title,
            'content': draft.content,
          })
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
    final pendingTasks = _queueBox.values.where((entry) => !entry.isProcessed).toList();
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
          await supabase.from('posts').update({
            'title': payload['title'],
            'content': payload['content'],
          }).eq('post_id', payload['postId']);
        } else if (task.actionType == 'DELETE_POST') {
          await supabase.from('posts').delete().eq('post_id', payload['postId']);
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
}
