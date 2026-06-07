import 'package:hive/hive.dart';
import '../config/app_enums.dart';
part 'local_draft.g.dart';

@HiveType(typeId: 1)
class LocalDraft {
  LocalDraft({
    required this.localId,
    required this.postId,
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
    required this.updatedAt,
    this.rejectionNote,
    this.imageUrls,
    this.hashtags,
  });

  @HiveField(0)
  String localId;

  @HiveField(1)
  String postId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String title;

  @HiveField(4)
  String content;

  @HiveField(5)
  PostStatus status;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String? rejectionNote;

  @HiveField(8)
  List<String>? imageUrls;

  @HiveField(9)
  List<String>? hashtags;
}
