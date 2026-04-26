import 'package:hive/hive.dart';

part 'comment_model.g.dart';

@HiveType(typeId: 15)
class CommentModel {
  const CommentModel({
    required this.commentId,
    required this.articleId,
    required this.userId,
    required this.content,
    required this.isSynced,
  });

  @HiveField(0)
  final String commentId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final bool isSynced;
}
