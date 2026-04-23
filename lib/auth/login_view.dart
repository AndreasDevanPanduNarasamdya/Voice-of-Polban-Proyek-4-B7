import 'package:flutter/material.dart';
import 'package:voice_of_polban/auth/login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginState();
}

class _LoginState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "JUDUL",
                style: TextStyle(fontSize: 30),
                textAlign: TextAlign.center,
              ),
              TextFormField(
                controller: _controller.usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Username tidak boleh kosong";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _controller.passwordController,
                decoration: InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Password tidak boleh kosong";
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(30),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _errorMessage = null);
                    if (_formKey.currentState!.validate()) {
                      final success = _controller.submitData(context);
                      if (!success) {
                        setState(
                          () => _errorMessage = "Username atau Password salah!",
                        );
                        Future.delayed(const Duration(seconds: 4), () {
                          if (mounted) setState(() => _errorMessage = null);
                        });
                      }
                    }
                  },
                  child: Text("Log In"),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
