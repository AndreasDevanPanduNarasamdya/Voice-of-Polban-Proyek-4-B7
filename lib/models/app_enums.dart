import 'package:hive/hive.dart';

part 'app_enums.g.dart';

@HiveType(typeId: 8)
enum UserRole {
  @HiveField(0)
  reader,

  @HiveField(1)
  writer,

  @HiveField(2)
  editor,
}

@HiveType(typeId: 9)
enum PostStatus {
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
