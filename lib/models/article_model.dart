import 'package:hive/hive.dart';

import 'app_enums.dart';

part 'article_model.g.dart';

@HiveType(typeId: 5)
class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.status,
    this.rejectionNote,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final ArticleCategory category;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final ArticleStatus status;

  @HiveField(6)
  final String? rejectionNote;

  @HiveField(7)
  final DateTime createdAt;
}
