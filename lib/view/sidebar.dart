import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/writer_view.dart';
import 'package:voice_of_polban/auth/auth_view.dart';
import 'package:voice_of_polban/view/editor_view.dart';
import '../models/app_enums.dart';

class AppSidebar extends StatelessWidget {
  final UserRole currentUserRole;
  const AppSidebar({super.key, required this.currentUserRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212), // Match Dark Theme
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                ),
                SizedBox(height: 10),
                Text(
                  'Voice of Polban',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildTile(context, Icons.book, 'Catatan Logbook'),
          _buildTile(context, Icons.save, 'Data Persistence'),

          // WRITER → Tulis Artikel
          if (currentUserRole == UserRole.writer)
            ListTile(
              leading: const Icon(Icons.edit_document, color: Colors.white),
              title: const Text(
                'Tulis Artikel',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WriterPage()),
                );
              },
            ),

          // EDITOR → Lihat Draft
          if (currentUserRole == UserRole.editor)
            ListTile(
              leading: const Icon(Icons.edit_document, color: Colors.white),
              title: const Text(
                'Lihat Draft',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditorPage()),
                );
              },
            ),

          const Divider(color: Color(0xFF333333)),
          _buildTile(context, Icons.settings, 'Pengaturan'),

          // Sign Out Logic
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pop(context),
    );
  }
}
