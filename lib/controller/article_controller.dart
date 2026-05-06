import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:voice_of_polban/auth/auth_service.dart';
import 'dart:io';
import 'dart:convert';
import '../models/app_enums.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import '../models/revision_history_model.dart';

class ArticleController {
  static const int _latestArticlesLimit = 5;
  final Uuid _uuid = const Uuid();

  // Inject the AuthService instead of reading the session box directly!
  final AuthService _authService;

  ArticleController({required AuthService authService})
    : _authService = authService;

  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('article_box');

  Box<RevisionHistoryModel> get _revisionBox =>
      Hive.box<RevisionHistoryModel>('revision_history_box');

  UserRole getCurrentUserRole() {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return UserRole.reader;

    final user = Hive.box<UserModel>('user_box').get(userId);
    return user?.role ?? UserRole.reader;
  }

  ArticleModel? getArticle(String articleId) => _articlesBox.get(articleId);

  List<ArticleModel> getLatestArticles({int limit = 10}) {
    final publishedArticles =
        _articlesBox.values
            .where((article) => article.status == ArticleStatus.published)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return publishedArticles.take(limit).toList();
  }

  void createDraft({
    required String title,
    required String content,
    required String sectionId,
    File? imageFile,
  }) {
    final currentUserId = _authService.getCurrentUserId();

    if (currentUserId == null) return;

    // Convert image to base64 if provided
    String? imageUrl;
    if (imageFile != null) {
      try {
        final bytes = imageFile.readAsBytesSync();
        imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (e) {
        print('Error converting image: $e');
      }
    }

    final newArticle = ArticleModel(
      articleId: _uuid.v4(),
      title: title,
      content: content,
      sectionId: sectionId,
      authorId: currentUserId,
      editorId: null,
      status: ArticleStatus.draft,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );

    _articlesBox.put(newArticle.articleId, newArticle);
  }

  List<ArticleModel> getLatestArticlesBySection(String sectionId) {
    return _articlesBox.values
        .where(
          (article) =>
              article.status == ArticleStatus.published &&
              article.sectionId == sectionId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
      ..take(_latestArticlesLimit);
  }

  List<ArticleModel> getPendingArticles() {
    return _articlesBox.values
        .where(
          (a) =>
              a.status == ArticleStatus.pending ||
              a.status == ArticleStatus.draft,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ArticleModel> getArticlesByAuthor(String authorId) {
    return _articlesBox.values
        .where((article) => article.authorId == authorId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void saveDraft({
    required String title,
    required String content,
    required String sectionId,
    required String authorId,
  }) {
    final String articleId = _uuid.v4();
    _articlesBox.put(
      articleId,
      ArticleModel(
        articleId: articleId,
        title: title,
        content: content,
        sectionId: sectionId,
        authorId: authorId,
        editorId: '',
        status: ArticleStatus.draft,
        createdAt: DateTime.now(),
      ),
    );
  }

  void submitDraft(String articleId) {
    _updateStatus(articleId, ArticleStatus.pending);
  }

  String? reviewArticle({
    required String articleId,
    required bool approved,
    required String note, // Strictly required now
  }) {
    // 1. The Anti-Mass-Approval Validation
    if (note.trim().isEmpty) {
      return "Catatan wajib diisi sebagai bukti artikel telah dibaca.";
    }

    final article = getArticle(articleId);
    final currentEditorId = _authService.getCurrentUserId();

    if (article == null || currentEditorId == null) {
      return "Terjadi kesalahan sistem. Sesi tidak valid.";
    }

    final newStatus = approved
        ? ArticleStatus.approved
        : ArticleStatus.rejected;

    // 2. Update article
    _articlesBox.put(
      articleId,
      article.copyWith(
        status: newStatus,
        editorId: currentEditorId,
        rejectionNote: note,
      ),
    );

    // 3. Persist the history securely
    _logRevision(
      articleId: articleId,
      editorId: currentEditorId,
      action: approved ? 'APPROVE' : 'REJECT',
      note: note.trim(),
    );

    return null; // Success!
  }

  // --- INTERNAL UTILS ---

  void _logRevision({
    required String articleId,
    required String editorId,
    required String action,
    required String note, // Reverted to required
  }) {
    final revision = RevisionHistoryModel(
      revisionId: _uuid.v4(),
      articleId: articleId,
      editorId: editorId,
      action: action,
      note: note,
    );

    _revisionBox.put(revision.revisionId, revision);
  }

  void publishArticle(String articleId) {
    if (!isEditor()) return;

    final article = _articlesBox.get(articleId);
    if (article == null) return;

    _articlesBox.put(
      articleId,
      article.copyWith(status: ArticleStatus.published),
    );
  }

  void archiveArticle(String articleId) {
    _updateStatus(articleId, ArticleStatus.archived);
  }

  void deleteArticle(String articleId) {
    _articlesBox.delete(articleId);
  }

  void _updateStatus(String articleId, ArticleStatus status) {
    _updateArticle(articleId, (article) => article.copyWith(status: status));
  }

  void _updateArticle(
    String articleId,
    ArticleModel Function(ArticleModel) update,
  ) {
    final article = _articlesBox.get(articleId);
    if (article == null) return;
    _articlesBox.put(articleId, update(article));
  }

  bool isEditor() {
    return getCurrentUserRole() == UserRole.editor;
  }
}
