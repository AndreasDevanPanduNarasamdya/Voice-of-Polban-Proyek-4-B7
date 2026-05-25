import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_of_polban/auth/auth_view.dart';
import 'package:voice_of_polban/auth/auth_controller.dart'; // Added this
import 'package:voice_of_polban/view/home_view.dart'; // Added this
import 'models/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Ensure Hive is initialized and all required boxes are opened before runApp
  await Hive.initFlutter();

  // Register adapters and open the canonical boxes (also safe if called twice)
  await setupHive();

  runApp(const VoiceOfPolbanApp());
}

class VoiceOfPolbanApp extends StatelessWidget {
  const VoiceOfPolbanApp({super.key});

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

      home: AuthController().currentUser != null
          ? const HomePage()
          : const LoginView(),
    );
  }
}
