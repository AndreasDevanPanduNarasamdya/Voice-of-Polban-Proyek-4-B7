import 'package:flutter/material.dart';
import 'screens/debug_dashboard.dart';
import 'models/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      home: const DebugDashboard(),
    );
  }
}
