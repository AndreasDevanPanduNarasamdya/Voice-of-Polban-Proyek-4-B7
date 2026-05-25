import 'package:hive/hive.dart';
part 'local_bookmark.g.dart';

@HiveType(typeId: 6)
class LocalBookmark {
  LocalBookmark({
    required this.bookmarkId,
    required this.postId,
    required this.userId,
    required this.isSynced,
  });

  @HiveField(0)
  String bookmarkId;

  @HiveField(1)
  String postId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  bool isSynced;
}
