import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:voice_of_polban/models/user_model.dart';

class LoginController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Box<UserModel> get _usersBox => Hive.box<UserModel>('users_box');

  UserModel? login(String username, String password) {
    for (final user in _usersBox.values) {
      if (user.name == username && user.password == password) {
        Hive.box('session_box').put('logged_in_user', user.name);
        print("Logged in as: ${user.role}");
        return user;
      }
    }
    return null;
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}
