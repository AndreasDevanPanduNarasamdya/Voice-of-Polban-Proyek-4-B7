import 'package:hive/hive.dart';

import '../models/user_model.dart';

class AuthController {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Box<UserModel> get _usersBox => Hive.box<UserModel>('user_box');

  Future<void> seedDummyUsers() async {
    if (_usersBox.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    await _usersBox.putAll({
      '1': UserModel(
        userId: '1',
        name: 'Reader Polban',
        email: 'reader@polban.ac.id',
        passwordHash: 'password123',
        role: 'reader',
        createdAt: now,
        updatedAt: now,
      ),
      '2': UserModel(
        userId: '2',
        name: 'Writer Polban',
        email: 'writer@polban.ac.id',
        passwordHash: 'password123',
        role: 'writer',
        createdAt: now,
        updatedAt: now,
      ),
      '3': UserModel(
        userId: '3',
        name: 'Editor Polban',
        email: 'editor@polban.ac.id',
        passwordHash: 'password123',
        role: 'editor',
        createdAt: now,
        updatedAt: now,
      ),
    });
  }

  UserModel? login(String email, String password) {
    for (final user in _usersBox.values) {
      if (user.email == email && user.passwordHash == password) {
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
