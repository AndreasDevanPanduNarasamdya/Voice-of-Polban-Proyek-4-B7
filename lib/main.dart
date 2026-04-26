import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/home_view.dart';
import 'package:voice_of_polban/view/article_view.dart';
import 'package:voice_of_polban/view/writer_view.dart';
import 'package:voice_of_polban/view/sidebar.dart';
import 'auth/login_view.dart';
import 'screens/debug_dashboard.dart';
import 'models/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupHive();
  await seedInitialUsers();
  await seedInitialArticles();
  runApp(const VoiceOfPolbanApp());
}

class VoiceOfPolbanApp extends StatelessWidget {
  const VoiceOfPolbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginView(),
    );
  }
}
