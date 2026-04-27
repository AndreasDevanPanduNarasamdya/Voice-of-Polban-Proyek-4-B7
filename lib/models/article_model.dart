import 'package:hive/hive.dart';
import 'app_enums.dart';
part 'article_model.g.dart';

@HiveType(typeId: 3)
class ArticleModel {
  const ArticleModel({
    required this.articleId,
    required this.title,
    required this.content,
    required this.sectionId,
    required this.authorId,
    this.editorId,
    required this.status,
    this.rejectionNote,
    required this.createdAt,
  });

  @HiveField(0)
  final String articleId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String sectionId;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String? editorId;

  @HiveField(6)
  final ArticleStatus status;

  @HiveField(7)
  final String? rejectionNote;

  @HiveField(8)
  final DateTime createdAt;

  ArticleModel copyWith({
    String? title,
    String? content,
    String? sectionId,
    ArticleStatus? status,
    String? editorId,
    String? rejectionNote,
  }) {
    return ArticleModel(
      articleId: articleId,
      title: title ?? this.title,
      content: content ?? this.content,
      sectionId: sectionId ?? this.sectionId,
      authorId: authorId,
      editorId: editorId ?? this.editorId,
      status: status ?? this.status,
      rejectionNote: rejectionNote ?? this.rejectionNote,
      createdAt: createdAt,
    );
  }
}
