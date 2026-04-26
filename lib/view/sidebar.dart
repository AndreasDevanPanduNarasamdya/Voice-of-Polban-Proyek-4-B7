import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/writer_view.dart';
import '../models/app_enums.dart';

class AppSidebar extends StatelessWidget {
  final UserRole currentUserRole;
  const AppSidebar({super.key, required this.currentUserRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.account_circle, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Menu Navigasi',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Catatan Logbook'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Data Persistence'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (currentUserRole == UserRole.writer)
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text('Tulis Artikel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WriterPage()),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
