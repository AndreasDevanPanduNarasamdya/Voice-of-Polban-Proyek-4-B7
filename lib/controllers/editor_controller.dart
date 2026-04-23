import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/app_enums.dart';
import '../models/article_model.dart';

class ArticleController {
  static const int _latestArticlesLimit = 5;

  final Uuid _uuid = const Uuid();

  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('articles_box');

  void saveDraft(
    String title,
    String content,
    ArticleCategory category,
    String authorId,
  ) {
    final String articleId = _uuid.v4();
    final ArticleModel draftArticle = ArticleModel(
      id: articleId,
      title: title,
      content: content,
      category: category,
      authorId: authorId,
      status: ArticleStatus.draft,
      createdAt: DateTime.now(),
    );

    _articlesBox.put(articleId, draftArticle);
  }

  void submitDraft(String articleId) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) {
      return;
    }

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: ArticleStatus.pending,
        rejectionNote: article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  void approveArticle(String articleId) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) {
      return;
    }

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: ArticleStatus.approved,
        rejectionNote: article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  void rejectArticle(String articleId, String note) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) {
      return;
    }

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: ArticleStatus.rejected,
        rejectionNote: note,
        createdAt: article.createdAt,
      ),
    );
  }

  void deleteArticle(String articleId) {
    _articlesBox.delete(articleId);
  }

  void publishArticle(String articleId) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) {
      return;
    }

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: ArticleStatus.published,
        rejectionNote: article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  void archiveArticle(String articleId) {
    final ArticleModel? article = _articlesBox.get(articleId);
    if (article == null) {
      return;
    }

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: ArticleStatus.archived,
        rejectionNote: article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  List<ArticleModel> getLatestArticlesByCategory(ArticleCategory category) {
    final List<ArticleModel> filteredArticles =
        _articlesBox.values
            .where(
              (ArticleModel article) =>
                  article.status == ArticleStatus.published &&
                  article.category == category,
            )
            .toList()
          ..sort((ArticleModel left, ArticleModel right) {
            return right.createdAt.compareTo(left.createdAt);
          });

    return filteredArticles.take(_latestArticlesLimit).toList();
  }
}
