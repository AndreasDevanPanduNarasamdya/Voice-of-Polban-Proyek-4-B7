import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';

import '../config/app_enums.dart';
import '../storage/cached_user.dart';

class AuthRepository {
  static const String _usersBoxName = 'cached_user_box';

  Box<CachedUser> get _usersBox => Hive.box<CachedUser>(_usersBoxName);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<CachedUser?> login(String input, String password) async {
    final normalizedInput = input.trim();
    final normalizedPassword = password.trim();

    if (normalizedInput.isEmpty || normalizedPassword.isEmpty) return null;

    try {
      final supabase = Supabase.instance.client;
      final hashedPassword = _hashPassword(normalizedPassword);

      final response = await supabase
          .from('users')
          .select('user_id, name, email, role, avatar_url')
          .or('email.eq.$normalizedInput,name.eq.$normalizedInput')
          .eq('password_hash', hashedPassword)
          .maybeSingle();

      if (response == null) {
        debugPrint('Login gagal: Kredensial salah atau tidak ditemukan');
        return null;
      }

      UserRole userRole = UserRole.reader;
      try {
        userRole = UserRole.values.byName(
          response['role'].toString().toLowerCase(),
        );
      } catch (_) {}

      final cachedUser = CachedUser(
        userId: response['user_id'].toString(),
        name: response['name'].toString(),
        email: response['email'].toString(),
        role: userRole,
        avatarUrl: response['avatar_url']?.toString() ?? '',
      );

      await _usersBox.put(cachedUser.userId, cachedUser);
      await Hive.box('session_box').put('logged_in_user_id', cachedUser.userId);

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase login failed: $e');

      try {
        final localUser = _usersBox.values.firstWhere(
          (u) => u.email == normalizedInput || u.name == normalizedInput,
        );
        await Hive.box(
          'session_box',
        ).put('logged_in_user_id', localUser.userId);
        return localUser;
      } catch (_) {
        return null;
      }
    }
  }

  Future<CachedUser?> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.reader,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();
    final hashedPassword = _hashPassword(normalizedPassword);

    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;

      final insertResponse = await supabase
          .from('users')
          .insert({
            'name': normalizedName,
            'email': normalizedEmail,
            'password_hash': hashedPassword,
            'role': role.name,
          })
          .select('user_id, name, email, role, avatar_url')
          .single();

      final cachedUser = CachedUser(
        userId: insertResponse['user_id'].toString(),
        name: insertResponse['name'].toString(),
        email: insertResponse['email'].toString(),
        role: role,
        avatarUrl: insertResponse['avatar_url']?.toString() ?? '',
      );

      await _usersBox.put(cachedUser.userId, cachedUser);
      await Hive.box('session_box').put('logged_in_user_id', cachedUser.userId);

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase registration failed: $e');
      return null;
    }
  }

  Future<CachedUser?> updateProfilePicture({
    required CachedUser user,
    required String imagePath,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      final file = File(imagePath);
      final fileExt = imagePath.split('.').last;
      final fileName =
          '${user.userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('avatars').upload(fileName, file);
      final newAvatarUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'avatar_url': newAvatarUrl})
          .eq('user_id', user.userId);

      final updatedUser = CachedUser(
        userId: user.userId,
        name: user.name,
        email: user.email,
        role: user.role,
        avatarUrl: newAvatarUrl,
      );

      await _usersBox.put(user.userId, updatedUser);
      Hive.box(
        'session_box',
      ).put('last_update', DateTime.now().toIso8601String());

      return updatedUser;
    } catch (e) {
      debugPrint('Failed to update avatar: $e');
      return null;
    }
  }

  Future<CachedUser?> updateName({
    required CachedUser user,
    required String newName,
  }) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return null;

    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('users')
          .update({'name': trimmedName})
          .eq('user_id', user.userId);

      final updatedUser = CachedUser(
        userId: user.userId,
        name: trimmedName,
        email: user.email,
        role: user.role,
        avatarUrl: user.avatarUrl,
      );

      await _usersBox.put(user.userId, updatedUser);
      return updatedUser;
    } catch (e) {
      debugPrint('Failed to update name: $e');
      return null;
    }
  }

  CachedUser? restoreSession() {
    final sessionBox = Hive.box('session_box');
    final userId = sessionBox.get('logged_in_user_id');
    if (userId != null) {
      return _usersBox.get(userId);
    }
    return null;
  }

  void clearSession() {
    Hive.box('session_box').delete('logged_in_user_id');
  }
}
