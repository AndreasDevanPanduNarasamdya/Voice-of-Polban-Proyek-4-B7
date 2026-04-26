import 'package:hive/hive.dart';

part 'revision_history_model.g.dart';

@HiveType(typeId: 6)
class RevisionHistoryModel {
  const RevisionHistoryModel({
    required this.revisionId,
    required this.articleId,
    required this.editorId,
    required this.action,
    required this.note,
  });

  @HiveField(0)
  final String revisionId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String editorId;

  @HiveField(3)
  final String action;

  @HiveField(4)
  final String note;
}
