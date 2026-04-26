import 'package:hive/hive.dart';

part 'bookmark_model.g.dart';

@HiveType(typeId: 9)
class BookmarkModel {
  const BookmarkModel({
    required this.bookmarkId,
    required this.articleId,
    required this.userId,
    required this.isSynced,
  });

  @HiveField(0)
  final String bookmarkId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final bool isSynced;
}
