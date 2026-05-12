import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../models/app_enums.dart';
import '../models/cached_user.dart';
import 'dart:convert';

class AuthController {
  static const String _usersBoxName = 'cached_user_box';

  // Singleton
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  AuthController._internal() {
    _restoreSession(); // ← goes HERE, inside the private constructor
  }

  CachedUser? _currentUser;

  Box<CachedUser> get _usersBox => Hive.box<CachedUser>(_usersBoxName);
  CachedUser? get currentUser => _currentUser;

  void _restoreSession() {
    final sessionBox = Hive.box('session_box');
    final userId = sessionBox.get('logged_in_user_id');
    if (userId != null) {
      _currentUser = _usersBox.get(userId);
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // 1. REAL LOGIN LOGIC
  Future<CachedUser?> login(String input, String password) async {
    final normalizedInput = input.trim();
    final normalizedPassword = password.trim();

    if (normalizedInput.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final hashedPassword = _hashPassword(normalizedPassword);

      // Check database for matching Name OR Email, AND matching Password
      final response = await supabase
          .from('users')
          .select('user_id, name, email, role')
          .or('email.eq.$normalizedInput,name.eq.$normalizedInput')
          .eq('password_hash', hashedPassword)
          .maybeSingle();

      if (response == null) {
        debugPrint('Login gagal: Kredensial salah atau tidak ditemukan');
        return null;
      }

      // Parse role safely
      UserRole userRole = UserRole.reader;
      try {
        userRole = UserRole.values.byName(response['role'].toString().toLowerCase());
      } catch (_) {}

      final cachedUser = CachedUser(
        userId: response['user_id'].toString(),
        name: response['name'].toString(),
        email: response['email'].toString(),
        role: userRole,
        avatarUrl: '', // Default empty
      );

      // Save session locally
      await _usersBox.put(cachedUser.userId, cachedUser);
      await Hive.box('session_box').put('logged_in_user_id', cachedUser.userId);
      _currentUser = cachedUser;

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase login failed: $e');
      
      // Offline fallback: check if they logged in before
      try {
        final localUser = _usersBox.values.firstWhere(
          (u) => u.email == normalizedInput || u.name == normalizedInput
        );
        await Hive.box('session_box').put('logged_in_user_id', localUser.userId);
        _currentUser = localUser;
        return localUser;
      } catch (_) {
        return null;
      }
    }
  }

  // 2. REAL REGISTRATION LOGIC
  Future<CachedUser?> register({
    required String name, 
    required String email, // Add this
    required String password, 
    UserRole role = UserRole.reader
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim(); // Add this
    final normalizedPassword = password.trim();
    final hashedPassword = _hashPassword(normalizedPassword);

    if (normalizedName.isEmpty || normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      
      final insertResponse = await supabase
          .from('users')
          .insert({
            'name': normalizedName,
            'email': normalizedEmail, // Use the real email
            'password_hash': hashedPassword,
            'role': role.name,
          })
          .select('user_id, name, email, role')
          .single();

      final cachedUser = CachedUser(
        userId: insertResponse['user_id'].toString(),
        name: insertResponse['name'].toString(),
        email: insertResponse['email'].toString(),
        role: role,
        avatarUrl: '',
      );

      await _usersBox.put(cachedUser.userId, cachedUser);
      await Hive.box('session_box').put('logged_in_user_id', cachedUser.userId);
      _currentUser = cachedUser;

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase registration failed: $e');
      return null; 
    }
  }

  CachedUser? logout() {
    Hive.box('session_box').delete('logged_in_user_id');
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
  }
}