import 'package:hive/hive.dart';
import '../models/article_model.dart';
import '../models/app_enums.dart';

class ArticleController {
  ArticleModel? getArticle(String articleId) {
    print("Fetching article $articleId from Hive...");
    final box = Hive.box<ArticleModel>('articles_box');

    return box.get(articleId);
  }

  Future<void> deleteArticle(String articleId) async {
    final box = Hive.box<ArticleModel>('articles_box');

    await box.delete(articleId);
    print("Article $articleId permanently deleted from Hive.");
  }

  Future<void> archiveArticle(String articleId) async {
    final box = Hive.box<ArticleModel>('articles_box');
    final existingArticle = box.get(articleId);

    if (existingArticle != null) {
      final archivedArticle = ArticleModel(
        id: existingArticle.id,
        title: existingArticle.title,
        content: existingArticle.content,
        category: existingArticle.category,
        authorId: existingArticle.authorId,
        status: ArticleStatus.archived,
        rejectionNote: existingArticle.rejectionNote,
        createdAt: existingArticle.createdAt,
      );

      await box.put(articleId, archivedArticle);
      print("Article $articleId status changed to Archived.");
    }
  }
}
