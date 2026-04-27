import 'package:hive/hive.dart';

part 'local_draft_model.g.dart';

@HiveType(typeId: 11)
class LocalDraftModel {
  const LocalDraftModel({
    required this.localId,
    required this.articleId,
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
  });

  @HiveField(0)
  final String localId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final String status;
}
