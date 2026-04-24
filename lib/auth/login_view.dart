import 'package:flutter/material.dart';
import 'package:voice_of_polban/auth/login_controller.dart';
import 'package:voice_of_polban/view/home_view.dart';

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

  void _onLoginPressed() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final user = _controller.login(
      _controller.usernameController.text,
      _controller.passwordController.text,
    );

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password salah!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _errorMessage = "Username atau Password salah!");
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("JUDUL", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
              TextFormField(
                controller: _controller.usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Username tidak boleh kosong";
                  return null;
                },
              ),
              TextFormField(
                controller: _controller.passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Password tidak boleh kosong";
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: ElevatedButton(
                  onPressed: _onLoginPressed,
                  child: const Text("Log In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}