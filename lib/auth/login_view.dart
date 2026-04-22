import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/home_view.dart';

class LoginView extends StatefulWidget {
  // final UserModel LoggedInUser;
  const LoginView({super.key /*,required this.LoggedInUser*/});

  @override
  State<LoginView> createState() => _LoginState();
}

class _LoginState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(30),
        child: Column(
          children: [
            Text(
              "JUDUL",
              style: TextStyle(fontSize: 30),
              textAlign: TextAlign.center,
            ),
            TextField(
              /*controller: ,*/ decoration: InputDecoration(
                labelText: "Username",
              ),
            ),
            TextField(
              /*controller: ,*/ decoration: InputDecoration(
                labelText: "Password",
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(30),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: Text("Log In"),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
