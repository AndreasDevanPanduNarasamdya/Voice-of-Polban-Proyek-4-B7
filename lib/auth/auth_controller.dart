import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_enums.dart';
import '../models/cached_user.dart';

class AuthController {
  static const String _usersBoxName = 'cached_user_box';

  CachedUser? _currentUser;

  Box<CachedUser> get _usersBox => Hive.box<CachedUser>(_usersBoxName);

  CachedUser? get currentUser => _currentUser;

  // ─────────────────────────────────────────────
  // RESTORE SESSION (Call this on app startup)
  // ─────────────────────────────────────────────
  Future<void> restoreSession() async {
    final session = _usersBox.get('current_session');
    if (session != null) {
      _currentUser = session;
      debugPrint('Restored active session for: ${session.email}');
    }
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  Future<CachedUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedName.isEmpty || normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw RegisterException('Semua field harus diisi.');
    }

    try {
      final supabase = Supabase.instance.client;

      // Cek apakah email sudah ada di server Supabase
      final existing = await supabase
          .from('users')
          .select('user_id')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (existing != null) {
        throw RegisterException('Email sudah terdaftar di server.');
      }

      // Insert user baru ke Supabase
      final insertResponse = await supabase
          .from('users')
          .insert({
            'name': normalizedName,
            'email': normalizedEmail,
            'password_hash': normalizedPassword, // plaintext sementara
            'role': UserRole.reader.name,
          })
          .select('user_id')
          .single();

      final supabaseUserId = insertResponse['user_id'] as String;
      debugPrint('User registered in Supabase: $supabaseUserId');

      final newUser = CachedUser(
        userId: supabaseUserId,
        name: normalizedName,
        email: normalizedEmail,
        role: UserRole.reader,
        avatarUrl: '',
      );

      // Wipe any old local data and save ONLY the new active session
      await _usersBox.clear();
      await _usersBox.put('current_session', newUser);
      _currentUser = newUser;

      return newUser;
    } on RegisterException {
      rethrow;
    } catch (e) {
      debugPrint('Register error: $e');
      throw RegisterException('Registrasi gagal. Periksa koneksi internet kamu.');
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  Future<CachedUser?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;

      // Strictly ask Supabase for the user data
      final response = await supabase
          .from('users')
          .select('user_id, name, email, role, password_hash')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (response == null) {
        debugPrint('User tidak ditemukan di database.');
        return null; 
      }

      // Validate the password
      final storedPassword = response['password_hash'] as String? ?? '';
      if (normalizedPassword != storedPassword) {
        debugPrint('Password salah.');
        return null;
      }

      final loggedInUser = CachedUser(
        userId: response['user_id'] as String,
        name: response['name'] as String,
        email: response['email'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == response['role'],
          orElse: () => UserRole.reader,
        ),
        avatarUrl: '', 
      );

      // Wipe the local database and save ONLY the current session
      await _usersBox.clear();
      await _usersBox.put('current_session', loggedInUser);
      _currentUser = loggedInUser;

      return loggedInUser;
    } catch (e) {
      debugPrint('Supabase login failed: $e');
      // No offline fallback! If internet fails, deny entry.
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  Future<void> logout() async {
    final previousUser = _currentUser;
    // Completely destroy the local session
    await _usersBox.clear(); 
    _currentUser = null;
    debugPrint('User logged out: ${previousUser?.email}');
  }
}

// ─────────────────────────────────────────────
// EXCEPTION
// ─────────────────────────────────────────────
class RegisterException implements Exception {
  RegisterException(this.message);
  final String message;

  @override
  String toString() => message;
}