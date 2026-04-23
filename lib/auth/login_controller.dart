import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/home_view.dart';

class LoginController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void submitData(BuildContext context) {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username == "admin" && password == "1234") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      print("${username} is right");
      print("${password} is right");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password salah!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("${username} is wrong");
      print("${password} is wrong");
    }
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}
