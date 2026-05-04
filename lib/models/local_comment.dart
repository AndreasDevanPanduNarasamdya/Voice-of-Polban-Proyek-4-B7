import 'package:hive/hive.dart';

part 'local_comment.g.dart';

@HiveType(typeId: 5)
class LocalComment {
  LocalComment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.isSynced,
  });

  @HiveField(0)
  String commentId;

  @HiveField(1)
  String postId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool isSynced;
}
