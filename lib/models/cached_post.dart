import 'package:hive/hive.dart';

part 'cached_post.g.dart';

@HiveType(typeId: 2)
class CachedPost {
  CachedPost({
    required this.postId,
    required this.cachedData,
    required this.cachedAt,
  });

  @HiveField(0)
  String postId;

  @HiveField(1)
  String cachedData;

  @HiveField(2)
  DateTime cachedAt;
}
