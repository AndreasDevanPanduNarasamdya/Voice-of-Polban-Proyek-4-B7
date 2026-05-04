import 'dart:convert';

import 'package:hive/hive.dart';
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

  LocalDraft saveDraft(String title, String content, String userId) {
    final draft = LocalDraft(
      localId: _uuid.v4(),
      postId: _uuid.v4(),
      userId: userId,
      title: title.trim(),
      content: content.trim(),
      status: PostStatus.draft,
      updatedAt: DateTime.now(),
    );

    _draftBox.put(draft.localId, draft);
    return draft;
  }

  SyncQueue? submitDraft(String localId) {
    final draft = _draftBox.get(localId);
    if (draft == null) {
      return null;
    }

    draft.status = PostStatus.pending;
    draft.updatedAt = DateTime.now();
    _draftBox.put(localId, draft);

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

    _queueBox.put(queueEntry.queueId, queueEntry);
    return queueEntry;
  }

  List<CachedPost> getOfflinePosts() {
    return _cachedPostsBox.values.toList(growable: false);
  }

  int get pendingQueueLength =>
      _queueBox.values.where((entry) => !entry.isProcessed).length;

  LocalDraft? getDraftById(String localId) => _draftBox.get(localId);
}
