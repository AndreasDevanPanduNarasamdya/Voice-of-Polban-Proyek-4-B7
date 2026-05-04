import 'package:hive/hive.dart';

import '../models/app_enums.dart';
import '../models/cached_user.dart';

class AuthController {
  static const String _usersBoxName = 'cached_user_box';

  CachedUser? _currentUser;

  Box<CachedUser> get _usersBox => Hive.box<CachedUser>(_usersBoxName);

  CachedUser? get currentUser => _currentUser;

  Future<void> seedDummyUsers() async {
    final users = <CachedUser>[
      CachedUser(
        userId: '1',
        name: 'Reader',
        email: 'reader@polban.ac.id',
        role: UserRole.reader,
        avatarUrl: '',
      ),
      CachedUser(
        userId: '2',
        name: 'Writer',
        email: 'writer@polban.ac.id',
        role: UserRole.writer,
        avatarUrl: '',
      ),
      CachedUser(
        userId: '3',
        name: 'Editor',
        email: 'editor@polban.ac.id',
        role: UserRole.editor,
        avatarUrl: '',
      ),
    ];

    for (final user in users) {
      await _usersBox.put(user.userId, user);
    }
  }

  CachedUser? login(String input, String password) {
    final normalizedInput = input.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedInput.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    if (normalizedPassword != 'password123') {
      return null;
    }

    final matchedUser = _usersBox.values.firstWhere(
      (user) =>
          user.email.toLowerCase() == normalizedInput ||
          user.name.toLowerCase() == normalizedInput ||
          user.role.name.toLowerCase() == normalizedInput,
      orElse: () => CachedUser(
        userId: '',
        name: '',
        email: '',
        role: UserRole.reader,
        avatarUrl: '',
      ),
    );

    if (matchedUser.userId.isEmpty) {
      return null;
    }

    _currentUser = matchedUser;
    return matchedUser;
  }

  CachedUser? logout() {
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
  }
}
