import 'package:hive/hive.dart';

part 'app_enums.g.dart';

@HiveType(typeId: 1)
enum UserRole {
  @HiveField(0)
  reader,

  @HiveField(1)
  writer,

  @HiveField(2)
  editor,
}

@HiveType(typeId: 2)
enum ArticleStatus {
  @HiveField(0)
  draft,

  @HiveField(1)
  pending,

  @HiveField(2)
  approved,

  @HiveField(3)
  rejected,

  @HiveField(4)
  published,

  @HiveField(5)
  archived,

  @HiveField(6)
  dropped,
}

@HiveType(typeId: 3)
enum ArticleCategory {
  @HiveField(0)
  akademik,

  @HiveField(1)
  beritaKampus,

  @HiveField(2)
  acara,

  @HiveField(3)
  ormawa,
}