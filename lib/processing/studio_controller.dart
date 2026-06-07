import 'package:flutter/foundation.dart';

import '../storage/cached_post.dart';
import '../storage/local_draft.dart';
import '../storage/sync_queue.dart';
import '../api/studio_repository.dart';

class StudioController {
  static final StudioController _instance = StudioController._internal();
  factory StudioController() => _instance;
  StudioController._internal();

  final StudioRepository _repository = StudioRepository();

  bool isLoading = false;
  String? errorMessage;

  List<CachedPost> _pendingPosts = [];
  List<CachedPost> get pendingPosts => _pendingPosts;

  int get pendingQueueLength => _repository.pendingQueueLength;

  LocalDraft? getDraftById(String localId) => _repository.getDraftById(localId);

  Future<LocalDraft?> saveDraft(
    String? title,
    String? content,
    String userId, {
    List<String>? imageUrls,
  }) async {
    isLoading = true;
    errorMessage = null;
    try {
      final persistentImageUrls = await _repository.persistDraftImages(
        imageUrls,
      );
      final draft = await _repository.saveDraft(
        title,
        content,
        userId,
        imageUrls: persistentImageUrls,
      );
      return draft;
    } catch (e) {
      errorMessage = 'Failed to save draft.';
      debugPrint('StudioController.saveDraft error: $e');
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<LocalDraft?> updateDraft(
    String localId,
    String newTitle,
    String newContent, {
    List<String>? imageUrls,
  }) async {
    try {
      final persistentImageUrls = await _repository.persistDraftImages(
        imageUrls,
      );
      return await _repository.updateDraft(
        localId,
        newTitle,
        newContent,
        imageUrls: persistentImageUrls,
      );
    } catch (e) {
      errorMessage = 'Failed to update draft.';
      debugPrint('StudioController.updateDraft error: $e');
      return null;
    }
  }

  Future<bool> deleteArticle(String id) async {
    try {
      return await _repository.deleteArticle(id);
    } catch (e) {
      errorMessage = 'Failed to delete article.';
      debugPrint('StudioController.deleteArticle error: $e');
      return false;
    }
  }

  Future<SyncQueue?> submitDraft(String localId) async {
    isLoading = true;
    errorMessage = null;
    try {
      final result = await _repository.submitDraft(localId);
      if (result == null) errorMessage = 'Draft not found.';
      return result;
    } catch (e) {
      errorMessage = 'Failed to submit draft.';
      debugPrint('StudioController.submitDraft error: $e');
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<void> syncMyArticles(String userId) async {
    try {
      await _repository.syncMyArticles(userId);
    } catch (e) {
      debugPrint('StudioController.syncMyArticles error: $e');
    }
  }

  Future<void> loadPendingPosts() async {
    isLoading = true;
    errorMessage = null;
    try {
      _pendingPosts = await _repository.fetchPendingPosts();
    } catch (e) {
      errorMessage = 'Failed to load pending posts.';
      debugPrint('StudioController.loadPendingPosts error: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<bool> approvePost(String postId, {String note = ''}) async {
    try {
      return await _repository.approvePost(postId, note: note);
    } catch (e) {
      errorMessage = 'Failed to approve post.';
      debugPrint('StudioController.approvePost error: $e');
      return false;
    }
  }

  Future<bool> rejectPost(String postId, {String note = ''}) async {
    try {
      return await _repository.rejectPost(postId, note: note);
    } catch (e) {
      errorMessage = 'Failed to reject post.';
      debugPrint('StudioController.rejectPost error: $e');
      return false;
    }
  }
}
