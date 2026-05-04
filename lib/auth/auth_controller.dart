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

  Future<CachedUser?> login(String input, String password) async {
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

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select('user_id, name, email, role')
          .eq('email', matchedUser.email)
          .maybeSingle();

      String supabaseUserId;

      if (response != null) {
        supabaseUserId = response['user_id'] as String;
        debugPrint('User found in Supabase: $supabaseUserId');
      } else {
        final insertResponse = await supabase
            .from('users')
            .insert({
              'name': matchedUser.name,
              'email': matchedUser.email,
              'password_hash': '123456',
              'role': matchedUser.role.name,
            })
            .select('user_id')
            .single();

        supabaseUserId = insertResponse['user_id'] as String;
        debugPrint('User created in Supabase: $supabaseUserId');
      }

      final cachedUser = CachedUser(
        userId: supabaseUserId,
        name: matchedUser.name,
        email: matchedUser.email,
        role: matchedUser.role,
        avatarUrl: matchedUser.avatarUrl,
      );

      await _usersBox.put(supabaseUserId, cachedUser);
      _currentUser = cachedUser;

      return cachedUser;
    } catch (e) {
      debugPrint('Supabase sync failed: $e. Falling back to local-only login.');
      _currentUser = matchedUser;
      return matchedUser;
    }
  }

  CachedUser? logout() {
    final previousUser = _currentUser;
    _currentUser = null;
    return previousUser;
  }
}
