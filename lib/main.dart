import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_of_polban/view/home_view.dart';
import 'auth/auth_view.dart';
import 'models/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupHive();
  final sessionBox = Hive.box('session_box');
  final String? activeUserId = sessionBox.get('logged_in_user_id');
  final bool isLoggedIn = activeUserId != null;

  runApp(VoiceOfPolbanApp(isLoggedIn: isLoggedIn));
}

class VoiceOfPolbanApp extends StatelessWidget {
  final bool isLoggedIn;

  const VoiceOfPolbanApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice of Polban',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8C00),
          surface: Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFFF8C00)),
        ),
      ),

      home: isLoggedIn ? const HomePage() : const LoginView(),
    );
  }
}
