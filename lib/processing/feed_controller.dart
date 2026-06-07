import 'package:flutter/foundation.dart';
import '../api/feed_repository.dart';
import '../storage/cached_post.dart';
import '../storage/comment_model.dart';
import '../config/app_enums.dart';
import 'dart:convert';

class FeedController {
  // Singleton
  static final FeedController _instance = FeedController._internal();
  factory FeedController() => _instance;
  FeedController._internal();

  final FeedRepository _repository = FeedRepository();

  SortMode _sortMode = SortMode.terbaru;

  // ─── UI State ────────────────────────────────────────────────────────────────

  bool isLoading = false;
  String? errorMessage;
  bool isSearching = false;

  List<CachedPost> _feed = [];
  List<CachedPost> get feed => _feed;

  List<CachedPost> _searchResults = [];
  List<CachedPost> get searchResults => _searchResults;

  SortMode get sortMode => _sortMode;

  void updateSortMode(SortMode mode) {
    _sortMode = mode;
  }

  // ─── Feed ────────────────────────────────────────────────────────────────────

  List<CachedPost> getOfflinePosts() => _repository.getOfflinePosts();

  Future<void> loadFeed() async {
    isLoading = true;
    errorMessage = null;

    try {
      _feed = await _repository.fetchFeed();
    } catch (e) {
      errorMessage = 'Failed to load feed.';
      debugPrint('FeedController.loadFeed error: $e');
      _feed = _repository.getOfflinePosts();
    } finally {
      isLoading = false;
    }
  }

  Future<List<CachedPost>> fetchFeed() async {
    return await _repository.fetchFeed();
  }

  Future<void> search(String query) async {
    isSearching = true;
    _searchResults = [];

    try {
      _searchResults = await _repository.searchPosts(query);
    } catch (e) {
      debugPrint('FeedController.search error: $e');
      _searchResults = [];
    } finally {
      isSearching = false;
    }
  }

  // ─── Comments ────────────────────────────────────────────────────────────────

  Future<List<CommentModel>> loadComments(String postId) async {
    try {
      return await _repository.fetchComments(postId);
    } catch (e) {
      debugPrint('FeedController.loadComments error: $e');
      return <CommentModel>[];
    }
  }

  Future<bool> submitComment({
    required String postId,
    required String content,
  }) async {
    try {
      await _repository.addComment(postId: postId, content: content);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('FeedController.submitComment error: $e');
      return false;
    }
  }

  // ─── Bookmarks ───────────────────────────────────────────────────────────────

  List<CachedPost> getOfflineBookmarks() => _repository.getOfflineBookmarks();

  Future<void> toggleBookmark(String postId) async {
    try {
      await _repository.toggleBookmark(postId);
    } catch (e) {
      errorMessage = 'Failed to update bookmark.';
      debugPrint('FeedController.toggleBookmark error: $e');
    }
  }

  Future<void> syncBookmarks() async {
    try {
      await _repository.syncBookmarks();
    } catch (e) {
      debugPrint('FeedController.syncBookmarks error: $e');
    }
  }

  // ─── Votes ───────────────────────────────────────────────────────────────────

  Future<bool> castVote({
    required String postId,
    required bool isUpvoteTarget,
  }) async {
    try {
      await _repository.castVote(
        postId: postId,
        isUpvoteTarget: isUpvoteTarget,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('FeedController.castVote error: $e');
      return false;
    }
  }

  void updateFeed(List<CachedPost> posts) {
    _feed = posts;
  }

  String _searchQuery = '';

  // Method to update search and return the filtered list
  List<CachedPost> getFilteredFeed() {
    // 1. Filter by search query
    List<CachedPost> results = _feed.where((post) {
      final data = jsonDecode(post.cachedData);
      final title = (data['title'] ?? '').toString().toLowerCase();
      final content = (data['content'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();

    // 2. Sort results
    switch (_sortMode) {
      case SortMode.terlama:
        results.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
        break;
      case SortMode.populer:
        results.sort((a, b) {
          final countA =
              int.tryParse(
                jsonDecode(a.cachedData)['upvote_count']?.toString() ?? '0',
              ) ??
              0;
          final countB =
              int.tryParse(
                jsonDecode(b.cachedData)['upvote_count']?.toString() ?? '0',
              ) ??
              0;
          return countB.compareTo(countA); // Descending (Popular first)
        });
        break;
      case SortMode.terbaru:
      default:
        results.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
        break;
    }
    return results;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
  }
}
