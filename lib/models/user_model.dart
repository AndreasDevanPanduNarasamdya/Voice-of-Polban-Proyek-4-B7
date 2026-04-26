import 'package:hive/hive.dart';
import 'app_enums.dart';
part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String passwordHash;

  @HiveField(4)
  final UserRole role;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;
}
