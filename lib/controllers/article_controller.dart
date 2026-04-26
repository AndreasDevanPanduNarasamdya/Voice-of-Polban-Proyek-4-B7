import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/article_model.dart';
import '../models/section_model.dart';

class ArticleController {
  static const int _latestArticlesLimit = 5;

  final Uuid _uuid = const Uuid();

  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('article_box');

  Box<SectionModel> get _sectionBox => Hive.box<SectionModel>('section_box');

  Future<void> seedDummySection() async {
    if (_sectionBox.isNotEmpty) {
      return;
    }

    await _sectionBox.put(
      'sec-1',
      SectionModel(
        sectionId: 'sec-1',
        name: 'Akademik',
        createdAt: DateTime.now(),
      ),
    );
  }

  void saveDraft(String title, String content, String authorId) {
    final String articleId = _uuid.v4();
    final ArticleModel draftArticle = ArticleModel(
      articleId: articleId,
      title: title,
      content: content,
      sectionId: 'sec-1',
      authorId: authorId,
      editorId: '',
      status: 'draft',
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
        articleId: article.articleId,
        title: article.title,
        content: article.content,
        sectionId: article.sectionId,
        authorId: article.authorId,
        editorId: article.editorId,
        status: 'pending',
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
        articleId: article.articleId,
        title: article.title,
        content: article.content,
        sectionId: article.sectionId,
        authorId: article.authorId,
        editorId: article.editorId,
        status: 'approved',
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
        articleId: article.articleId,
        title: article.title,
        content: article.content,
        sectionId: article.sectionId,
        authorId: article.authorId,
        editorId: article.editorId,
        status: 'rejected',
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
        articleId: article.articleId,
        title: article.title,
        content: article.content,
        sectionId: article.sectionId,
        authorId: article.authorId,
        editorId: article.editorId,
        status: 'published',
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
        articleId: article.articleId,
        title: article.title,
        content: article.content,
        sectionId: article.sectionId,
        authorId: article.authorId,
        editorId: article.editorId,
        status: 'archived',
        rejectionNote: article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  List<ArticleModel> getLatestArticlesByCategory(String sectionId) {
    final List<ArticleModel> filteredArticles =
        _articlesBox.values
            .where(
              (ArticleModel article) =>
                  article.status == 'published' &&
                  article.sectionId == sectionId,
            )
            .toList()
          ..sort((ArticleModel left, ArticleModel right) {
            return right.createdAt.compareTo(left.createdAt);
          });

    return filteredArticles.take(_latestArticlesLimit).toList();
  }
}
