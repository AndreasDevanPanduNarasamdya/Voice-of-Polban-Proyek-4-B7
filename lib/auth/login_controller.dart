import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:voice_of_polban/models/user_model.dart';
import 'package:voice_of_polban/view/home_view.dart';

class LoginController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool submitData(BuildContext context) {
    String typedUsername = usernameController.text;
    String typedPassword = passwordController.text;

    final box = Hive.box<UserModel>('users_box');

    UserModel? loggedInUser;

    try {
      loggedInUser = box.values.firstWhere(
        (user) => user.name == typedUsername && user.password == typedPassword,
      );
    } catch (e) {
      loggedInUser = null;
    }

    if (loggedInUser != null) {
      print("$typedUsername is right");
      print("$typedPassword is right");
      print("Logged in as: ${loggedInUser.role}");

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return true;
    } else {
      print("$typedUsername is wrong");
      print("$typedPassword is wrong");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password salah!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}
