import 'package:hive/hive.dart';

part 'article_cache_model.g.dart';

@HiveType(typeId: 7)
class ArticleCacheModel {
  const ArticleCacheModel({
    required this.cacheId,
    required this.articleId,
    required this.sectionId,
    required this.cachedData,
  });

  @HiveField(0)
  final String cacheId;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String sectionId;

  @HiveField(3)
  final Map<String, dynamic> cachedData;
}
