import 'package:hive/hive.dart';

import '../models/app_enums.dart';
import '../models/user_model.dart';

class AuthController {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Box<UserModel> get _usersBox => Hive.box<UserModel>('users_box');

  Future<void> seedDummyUsers() async {
    if (_usersBox.isNotEmpty) {
      return;
    }

    await _usersBox.putAll({
      '1': const UserModel(
        id: '1',
        name: 'Reader Polban',
        email: 'reader@polban.ac.id',
        password: 'password123',
        role: UserRole.reader,
      ),
      '2': const UserModel(
        id: '2',
        name: 'Writer Polban',
        email: 'writer@polban.ac.id',
        password: 'password123',
        role: UserRole.writer,
      ),
      '3': const UserModel(
        id: '3',
        name: 'Editor Polban',
        email: 'editor@polban.ac.id',
        password: 'password123',
        role: UserRole.editor,
      ),
    });
  }

  UserModel? login(String email, String password) {
    for (final user in _usersBox.values) {
      if (user.email == email && user.password == password) {
        _currentUser = user;
        return user;
      }
    }

    return null;
  }

  void logout() {
    _currentUser = null;
  }
}
