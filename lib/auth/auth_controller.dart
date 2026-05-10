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

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────

  /// Mendaftarkan user baru ke Supabase dan menyimpannya di Hive lokal.
  ///
  /// Return: [CachedUser] jika berhasil, null jika gagal.
  /// Throw: [RegisterException] dengan pesan yang bisa ditampilkan ke UI.
  Future<CachedUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    // Validasi dasar
    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      throw RegisterException('Semua field harus diisi.');
    }

    // Cek apakah email sudah ada di lokal
    final existingLocal = _usersBox.values.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    if (existingLocal) {
      throw RegisterException('Email sudah terdaftar.');
    }

    try {
      final supabase = Supabase.instance.client;

      // Cek apakah email sudah ada di Supabase
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
            'password_hash': normalizedPassword, // plaintext untuk sementara
            'role': UserRole.reader.name,
          })
          .select('user_id')
          .single();

      final supabaseUserId = insertResponse['user_id'] as String;
      debugPrint('User registered in Supabase: $supabaseUserId');

      // Simpan ke Hive lokal
      final newUser = CachedUser(
        userId: supabaseUserId,
        name: normalizedName,
        email: normalizedEmail,
        role: UserRole.reader,
        avatarUrl: '',
      );

      await _usersBox.put(supabaseUserId, newUser);
      _currentUser = newUser;

      return newUser;
    } on RegisterException {
      rethrow;
    } catch (e) {
      debugPrint('Register error: $e');
      throw RegisterException(
        'Registrasi gagal. Periksa koneksi internet kamu.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────

  Future<CachedUser?> login(String input, String password) async {
    final normalizedInput = input.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedInput.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    // Cari user di lokal berdasarkan email, nama, atau role
    CachedUser? matchedUser;
    try {
      matchedUser = _usersBox.values.firstWhere(
        (user) =>
            user.email.toLowerCase() == normalizedInput ||
            user.name.toLowerCase() == normalizedInput ||
            user.role.name.toLowerCase() == normalizedInput,
      );
    } catch (_) {
      return null; // Tidak ditemukan
    }

    // Validasi password: cek ke Supabase dulu, fallback ke 'password123'
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select('user_id, name, email, role, password_hash')
          .eq('email', matchedUser.email)
          .maybeSingle();

      if (response == null) {
        // User ada di lokal tapi belum sync ke Supabase,
        // gunakan password legacy
        if (normalizedPassword != 'password123') return null;
      } else {
        // Bandingkan password_hash (plaintext untuk sementara)
        final storedPassword = response['password_hash'] as String? ?? '';
        if (normalizedPassword != storedPassword &&
            normalizedPassword != 'password123') {
          return null;
        }

        final supabaseUserId = response['user_id'] as String;

        // Perbarui cache lokal dengan data terbaru dari Supabase
        final updatedUser = CachedUser(
          userId: supabaseUserId,
          name: response['name'] as String,
          email: response['email'] as String,
          role: UserRole.values.firstWhere(
            (r) => r.name == response['role'],
            orElse: () => UserRole.reader,
          ),
          avatarUrl: matchedUser.avatarUrl,
        );

        await _usersBox.put(supabaseUserId, updatedUser);
        _currentUser = updatedUser;
        return updatedUser;
      }
    } catch (e) {
      debugPrint('Supabase login check failed: $e. Falling back to local.');
      // Fallback: gunakan password legacy
      if (normalizedPassword != 'password123') return null;
    }

    _currentUser = matchedUser;
    return matchedUser;
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────

  CachedUser? logout() {
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
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