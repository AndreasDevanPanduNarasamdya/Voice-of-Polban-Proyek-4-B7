import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_enums.dart';
import '../storage/cached_post.dart';
import '../storage/cached_user.dart';
import '../storage/local_draft.dart';
import '../storage/sync_queue.dart';

class StudioRepository {
  static const String _draftBoxName = 'local_draft_box';
  static const String _cachedPostsBoxName = 'cached_post_box';
  static const String _queueBoxName = 'sync_queue_box';

  final Uuid _uuid = const Uuid();

  Box<LocalDraft> get _draftBox => Hive.box<LocalDraft>(_draftBoxName);
  Box<CachedPost> get _cachedPostsBox =>
      Hive.box<CachedPost>(_cachedPostsBoxName);
  Box<SyncQueue> get _queueBox => Hive.box<SyncQueue>(_queueBoxName);

  LocalDraft? getDraftById(String localId) => _draftBox.get(localId);

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  Future<LocalDraft> saveDraft(
    String? title,
    String? content,
    String userId, {
    List<String>? imageUrls,
    List<String>? hashtags,
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
        hashtags: hashtags,
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
        hashtags: hashtags,
      );

      await _draftBox.put(draft.localId, draft);
      return draft;
    }
  }

  Future<List<String>> persistDraftImages(List<String>? paths) async {
    if (paths == null || paths.isEmpty) return [];

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final persistentPaths = <String>[];

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];

      if (path.startsWith('http')) {
        persistentPaths.add(path);
        continue;
      }

      try {
        final sourceFile = File(path);
        if (!await sourceFile.exists()) {
          debugPrint('Draft image source not found: $path');
          continue;
        }

        if (p.isWithin(documentsDirectory.path, sourceFile.path) ||
            p.equals(
              p.normalize(sourceFile.path),
              p.normalize(documentsDirectory.path),
            )) {
          persistentPaths.add(sourceFile.path);
          continue;
        }

        final extension = p.extension(path).isNotEmpty
            ? p.extension(path)
            : '.jpg';
        final fileName =
            'draft_img_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
        final persistentFile = File(p.join(documentsDirectory.path, fileName));

        if (await persistentFile.exists()) {
          persistentPaths.add(persistentFile.path);
          continue;
        }

        final copiedFile = await sourceFile.copy(persistentFile.path);
        persistentPaths.add(copiedFile.path);
      } catch (e) {
        debugPrint('Failed to persist draft image $path: $e');
        persistentPaths.add(path);
      }
    }

    return persistentPaths;
  }

  Future<LocalDraft?> updateDraft(
    String localId,
    String newTitle,
    String newContent, {
    List<String>? imageUrls,
    List<String>? hashtags,
  }) async {
    final draft = _draftBox.get(localId);
    if (draft == null) return null;

    draft.title = newTitle.trim().isNotEmpty ? newTitle.trim() : draft.title;
    draft.content = newContent.trim().isNotEmpty
        ? newContent.trim()
        : draft.content;
    draft.imageUrls = imageUrls;
    draft.hashtags = hashtags;
    draft.updatedAt = DateTime.now();
    await _draftBox.put(localId, draft);

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

  Future<bool> deleteArticle(String id) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('posts').delete().eq('post_id', id);

      if (_cachedPostsBox.containsKey(id)) await _cachedPostsBox.delete(id);
      if (_draftBox.containsKey(id)) await _draftBox.delete(id);

      return true;
    } catch (e) {
      debugPrint(
        'Failed to delete article online: $e. Queuing offline delete.',
      );

      if (_cachedPostsBox.containsKey(id)) await _cachedPostsBox.delete(id);
      if (_draftBox.containsKey(id)) await _draftBox.delete(id);

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

  Future<List<String>> uploadImages(List<String>? paths, String postId) async {
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

  // 1. Add rawHashtags to the parameters
  Future<SyncQueue?> submitDraft(
    String localId, {
    List<String>? rawHashtags,
  }) async {
    final draft = _draftBox.get(localId);
    if (draft == null) return null;

    final finalUrls = await uploadImages(draft.imageUrls, draft.postId);
    draft.imageUrls = finalUrls;

    final supabase = Supabase.instance.client;

    try {
      final existingPost = await supabase
          .from('posts')
          .select()
          .eq('post_id', draft.postId)
          .maybeSingle();

      if (existingPost != null) {
        debugPrint('Updating existing Supabase post: ${draft.postId}');
        await supabase
            .from('posts')
            .update({'status': PostStatus.pending.name})
            .eq('post_id', draft.postId);
      } else {
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

      // ==========================================
      // PASTE THE HASHTAG LOGIC HERE
      // ==========================================
      if (rawHashtags != null && rawHashtags.isNotEmpty) {
        final cleanHashtags = rawHashtags
            .map((tag) => tag.trim().toLowerCase().replaceAll('#', ''))
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList();

        if (cleanHashtags.isNotEmpty) {
          try {
            await supabase.rpc(
              'process_post_hashtags',
              params: {'p_post_id': draft.postId, 'p_hashtags': cleanHashtags},
            );
            debugPrint('Hashtags processed successfully.');
          } catch (e) {
            debugPrint('Failed to process hashtags: $e');
          }
        }
      }

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
          'imageUrls': finalUrls,
          'updatedAt': draft.updatedAt.toIso8601String(),
          'hashtags': draft.hashtags,
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
          'hashtags': draft.hashtags,
        }),
        isProcessed: false,
        createdAt: DateTime.now(),
      );

      await _queueBox.put(queueEntry.queueId, queueEntry);
      return queueEntry;
    }
  }

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

      // Update cached_post_box
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

      // ← ADD THIS: also update local_draft_box so the UI reacts immediately
      final draft = _draftBox.get(postId);
      if (draft != null) {
        draft.status = PostStatus.published;
        draft.rejectionNote = note.isNotEmpty ? note : draft.rejectionNote;
        draft.updatedAt = DateTime.now();
        await _draftBox.put(postId, draft);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to approve post $postId: $e');
      return false;
    }
  }

  Future<bool> rejectPost(String postId, {String note = ''}) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'status': PostStatus.rejected.name, 'rejection_note': note})
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

      final draft = _draftBox.get(postId);
      if (draft != null) {
        draft.status = PostStatus.rejected;
        draft.rejectionNote = note.isNotEmpty ? note : draft.rejectionNote;
        draft.updatedAt = DateTime.now();
        await _draftBox.put(postId, draft);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to reject post $postId: $e');
      return false;
    }
  }

  Future<void> syncMyArticles(String userId) async {
    final supabase = Supabase.instance.client;
    try {
      final rows = await supabase
          .from('posts')
          .select('''
      post_id, title, content, author_id, status, created_at, edited_at, rejection_note, 
      attachments(attachment_details(file_path)),
      hashtags:post_hashtags(hashtags(name)) 
    ''')
          .eq('author_id', userId);

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final List<String> hashtags =
            (map['hashtags'] as List<dynamic>?)
                ?.map((h) => h['hashtags']['name'].toString())
                .toList() ??
            [];
        final postId = (map['post_id'] ?? '').toString();
        if (postId.isEmpty) continue;

        final updatedAt =
            DateTime.tryParse(
              (map['edited_at'] ?? map['created_at'] ?? '').toString(),
            ) ??
            DateTime.now();

        final existingDraft = _draftBox.get(postId);
        if (existingDraft != null) {
          if (existingDraft.updatedAt.isAfter(updatedAt)) {
            // Parse status inline here, no variable needed yet
            PostStatus serverStatus = PostStatus.draft;
            try {
              if (map['status'] != null) {
                serverStatus = PostStatus.values.byName(
                  map['status'].toString().toLowerCase(),
                );
              }
            } catch (_) {}

            if (existingDraft.status != serverStatus) {
              existingDraft.status = serverStatus;
              existingDraft.rejectionNote = map['rejection_note']?.toString();
              await _draftBox.put(existingDraft.localId, existingDraft);
            }
            continue;
          }
        }

        PostStatus status = PostStatus.draft;
        try {
          if (map['status'] != null) {
            status = PostStatus.values.byName(
              map['status'].toString().toLowerCase(),
            );
          }
        } catch (_) {}

        List<String> imageUrls = [];
        final attachments = map['attachments'] as List<dynamic>?;
        if (attachments != null && attachments.isNotEmpty) {
          final details =
              attachments.first['attachment_details'] as List<dynamic>?;
          if (details != null) {
            imageUrls = details.map((d) => d['file_path'].toString()).toList();
          }
        }

        if (existingDraft != null && existingDraft.imageUrls != null) {
          final localPaths = existingDraft.imageUrls!
              .where((p) => !p.startsWith('http'))
              .toList();
          imageUrls.addAll(localPaths);
          imageUrls = imageUrls.toSet().toList();
        }

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
          hashtags: hashtags.isEmpty ? null : hashtags,
        );

        await _draftBox.put(draft.localId, draft);
      }
    } catch (e) {
      debugPrint('Failed to sync user articles from Supabase: $e');
    }
  }
}
