import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../models/app_enums.dart';
import '../models/cached_user.dart';
import 'dart:convert';

class AuthController {
  static const String _usersBoxName = 'cached_user_box';

  CachedUser? _currentUser;

  Box<CachedUser> get _usersBox => Hive.box<CachedUser>(_usersBoxName);
  CachedUser? get currentUser => _currentUser;

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
      _currentUser = cachedUser;

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase login failed: $e');
      
      // Offline fallback: check if they logged in before
      try {
        final localUser = _usersBox.values.firstWhere(
          (u) => u.email == normalizedInput || u.name == normalizedInput
        );
        _currentUser = localUser;
        return localUser;
      } catch (_) {
        return null;
      }
    }
  }

  // 2. REAL REGISTRATION LOGIC
  Future<CachedUser?> register(String input, String password) async {
    final normalizedInput = input.trim();
    final normalizedPassword = password.trim();
    final hashedPassword = _hashPassword(normalizedPassword);

    if (normalizedInput.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Since UI only has 1 field for "Nama atau Email", we guess the email
      final emailValue = normalizedInput.contains('@') 
          ? normalizedInput 
          : '$normalizedInput@polban.ac.id';

      // Insert new user into the database. Defaults role to 'reader'
      final insertResponse = await supabase
          .from('users')
          .insert({
            'name': normalizedInput,
            'email': emailValue,
            'password_hash': hashedPassword,
            'role': UserRole.reader.name,
          })
          .select('user_id, name, email, role')
          .single();

      final cachedUser = CachedUser(
        userId: insertResponse['user_id'].toString(),
        name: insertResponse['name'].toString(),
        email: insertResponse['email'].toString(),
        role: UserRole.reader,
        avatarUrl: '',
      );

      // Save session locally
      await _usersBox.put(cachedUser.userId, cachedUser);
      _currentUser = cachedUser;

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase registration failed: $e');
      return null; // Usually fails if email/name already exists
    }
  }

  CachedUser? logout() {
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
  }
}