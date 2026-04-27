import 'package:hive/hive.dart';

part 'attachment_model.g.dart';

@HiveType(typeId: 14)
class AttachmentModel {
  const AttachmentModel({
    required this.attachmentId,
    required this.articleId,
    required this.type,
    required this.filePath,
  });

  @HiveField(0)
  final String attachmentId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String filePath;
}
