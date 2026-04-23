import 'package:flutter/material.dart';
import 'package:voice_of_polban/auth/login_controller.dart';
import 'package:voice_of_polban/view/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key /*,required this.LoggedInUser*/});

  @override
  State<LoginView> createState() => _LoginState();
}

class _LoginState extends State<LoginView> {
  final LoginController _controller = LoginController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return (Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              "JUDUL",
              style: TextStyle(fontSize: 30),
              textAlign: TextAlign.center,
            ),
            TextField(
              controller: _controller.usernameController, decoration: InputDecoration(
                labelText: "Username",
              ),
            ),
            TextField(
              controller: _controller.passwordController, decoration: InputDecoration(
                labelText: "Password",
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(30),
              child: ElevatedButton(
                onPressed: () {_controller.submitData(context);},
                child: Text("Log In"),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
