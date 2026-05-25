import '../config/app_enums.dart';
import '../storage/cached_user.dart';
import '../api/auth_repository.dart';

class AuthController {
  // Singleton
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  AuthController._internal() {
    _restoreSession();
  }

  final AuthRepository _repository = AuthRepository();

  CachedUser? _currentUser;
  CachedUser? get currentUser => _currentUser;

  void _restoreSession() {
    _currentUser = _repository.restoreSession();
  }

  Future<CachedUser?> login(String input, String password) async {
    final user = await _repository.login(input, password);
    _currentUser = user;
    return user;
  }

  Future<CachedUser?> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.reader,
  }) async {
    final user = await _repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    _currentUser = user;
    return user;
  }

  Future<bool> updateProfilePicture(String imagePath) async {
    final user = _currentUser;
    if (user == null) return false;

    final updatedUser = await _repository.updateProfilePicture(
      user: user,
      imagePath: imagePath,
    );

    if (updatedUser != null) {
      _currentUser = updatedUser;
      return true;
    }
    return false;
  }

  CachedUser? logout() {
    _repository.clearSession();
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
  }
}
