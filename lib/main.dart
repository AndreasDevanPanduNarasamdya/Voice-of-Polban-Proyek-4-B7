import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/home_view.dart';
import 'package:voice_of_polban/view/article_view.dart';
import 'package:voice_of_polban/view/writer_view.dart';
import 'package:voice_of_polban/view/sidebar.dart';
import 'auth/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice of Polban',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}