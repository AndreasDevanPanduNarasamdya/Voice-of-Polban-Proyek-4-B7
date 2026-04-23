import 'package:hive/hive.dart';

import 'app_enums.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final UserRole role;
}
