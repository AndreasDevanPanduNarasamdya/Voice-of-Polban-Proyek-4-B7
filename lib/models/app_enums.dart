import 'package:hive/hive.dart';

part 'app_enums.g.dart';

@HiveType(typeId: 4)
enum UserRole {
  @HiveField(0)
  reader,
  @HiveField(1)
  writer,
  @HiveField(2)
  editor,
}

@HiveType(typeId: 5)
enum ArticleStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  pending,
  @HiveField(2)
  approved,
  @HiveField(3)
  published,
  @HiveField(4)
  rejected,
  @HiveField(5)
  archived,
}

enum AuthResult { success, userNotFound, wrongPassword }

enum ArticleCategory { beritaKampus, ormawa, akademik, event }
