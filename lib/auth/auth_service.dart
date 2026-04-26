import 'package:bcrypt/bcrypt.dart';
import 'package:hive/hive.dart';
import 'package:voice_of_polban/models/user_model.dart';
import 'package:voice_of_polban/models/app_enums.dart';

class AuthService {
  static const String _usersBoxName = 'user_box';
  static const String _sessionBoxName = 'session_box';
  static const String _sessionKey = 'logged_in_user_id';

  Box<UserModel> get _usersBox => Hive.box<UserModel>(_usersBoxName);
  Box get _sessionBox => Hive.box(_sessionBoxName);

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool _checkPassword(String plainPassword, String hashedPassword) {
    return BCrypt.checkpw(plainPassword, hashedPassword);
  }

  AuthResult login(String input, String password) {
    for (final user in _usersBox.values) {
      if (user.email == input || user.name == input) {
        if (_checkPassword(password, user.passwordHash)) {
          _sessionBox.put(_sessionKey, user.userId);
          return AuthResult.success;
        } else {
          return AuthResult.wrongPassword;
        }
      }
    }
    return AuthResult.userNotFound;
  }

  String? register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.reader,
  }) {
    for (final user in _usersBox.values) {
      if (user.email == email) return "Email sudah digunakan";
      if (user.name == name) return "Nama pengguna sudah dipakai";
    }

    final now = DateTime.now();

    final newUser = UserModel(
      userId: 'usr_${now.millisecondsSinceEpoch}',
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      role: role,
      createdAt: now,
      updatedAt: now,
    );

    _usersBox.put(newUser.userId, newUser);
    return null;
  }

  UserRole getCurrentUserRole() {
    final userId = _sessionBox.get(_sessionKey);
    if (userId == null) return UserRole.reader;

    final user = _usersBox.get(userId);
    return user?.role ?? UserRole.reader;
  }

  void logout() {
    _sessionBox.delete(_sessionKey);
  }

  String? getCurrentUserId() {
    return _sessionBox.get(_sessionKey);
  }
}
