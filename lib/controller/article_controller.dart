import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/app_enums.dart';
import '../models/article_model.dart';

class ArticleController {
  static const int _latestArticlesLimit = 5;
  final Uuid _uuid = const Uuid();

  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('articles_box');

  // ← single getter, used by ArticlePage
  ArticleModel? getArticle(String articleId) {
    return _articlesBox.get(articleId);
  }

  // ← used by HomePage
  List<ArticleModel> getLatestArticles() {
    return _articlesBox.values
        .where((article) => article.status == ArticleStatus.published)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ArticleModel> getLatestArticlesByCategory(ArticleCategory category) {
    return _articlesBox.values
        .where((article) =>
            article.status == ArticleStatus.published &&
            article.category == category)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
        ..take(_latestArticlesLimit).toList();
  }

  void saveDraft(String title, String content, ArticleCategory category, String authorId) {
    final String articleId = _uuid.v4();
    _articlesBox.put(
      articleId,
      ArticleModel(
        id: articleId,
        title: title,
        content: content,
        category: category,
        authorId: authorId,
        status: ArticleStatus.draft,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _updateStatus(String articleId, ArticleStatus status, {String? rejectionNote}) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) return;

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: status,
        rejectionNote: rejectionNote ?? article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  void submitDraft(String articleId) => _updateStatus(articleId, ArticleStatus.pending);
  void approveArticle(String articleId) => _updateStatus(articleId, ArticleStatus.approved);
  void publishArticle(String articleId) => _updateStatus(articleId, ArticleStatus.published);
  void archiveArticle(String articleId) => _updateStatus(articleId, ArticleStatus.archived);
  void rejectArticle(String articleId, String note) => _updateStatus(articleId, ArticleStatus.rejected, rejectionNote: note);
  void deleteArticle(String articleId) => _articlesBox.delete(articleId);
}