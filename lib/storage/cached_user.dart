import 'package:hive/hive.dart';
import '../config/app_enums.dart';
part 'cached_user.g.dart';

@HiveType(typeId: 7)
class CachedUser {
  CachedUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  @HiveField(0)
  String userId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  UserRole role;

  @HiveField(4)
  String? avatarUrl;
}
