import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  static const Color _cardColor = Color(0xFF16213E);
  static const Color _accentColor = Color(0xFF0F3460);
  static const Color _highlightColor = Color(0xFFE94560);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: _accentColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.account_circle, color: Colors.white, size: 52),
                SizedBox(height: 10),
                Text(
                  'Voice of Polban',
                  style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _drawerItem(context, Icons.home, 'Beranda'),
          _drawerItem(context, Icons.language, 'Umum'),
          _drawerItem(context, Icons.emoji_events, 'Lomba'),
          _drawerItem(context, Icons.event, 'Event'),
          _drawerItem(context, Icons.group, 'Ormawa'),
          const Divider(color: Colors.white12),
          _drawerItem(context, Icons.settings, 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label) => ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        onTap: () => Navigator.pop(context),
      );
}