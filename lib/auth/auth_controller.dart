import 'package:voice_of_polban/models/app_enums.dart';
import 'auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final RegExp _emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

  String? login(String input, String password) {
    if (input.trim().isEmpty || password.trim().isEmpty) {
      return "Kolom tidak boleh kosong";
    }

    final result = _authService.login(input.trim(), password.trim());

    switch (result) {
      case AuthResult.success:
        return null;
      case AuthResult.userNotFound:
        return "Akun tidak ditemukan. Silakan daftar terlebih dahulu.";
      case AuthResult.wrongPassword:
        return "Kata sandi salah.";
    }
  }

  String? register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.reader,
  }) {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      return "Semua kolom wajib diisi";
    }

    if (!_emailRegex.hasMatch(email.trim())) {
      return "Format email tidak valid";
    }

    if (password.length < 6) {
      return "Kata sandi minimal 6 karakter";
    }

    return _authService.register(
      name: name.trim(),
      email: email.trim(),
      password: password.trim(),
      role: role,
    );
  }

  void logout() {
    _authService.logout();
  }
}
