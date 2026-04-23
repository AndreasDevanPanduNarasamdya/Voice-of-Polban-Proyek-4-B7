import 'package:flutter/material.dart';

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('VOP Prototype'),
        ),
        body: const Center(),
      ),
    );
  }
}