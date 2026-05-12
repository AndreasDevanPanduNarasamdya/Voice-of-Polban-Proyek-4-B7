import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/writer_view.dart';
import 'package:voice_of_polban/auth/auth_view.dart';
import 'package:voice_of_polban/view/editor_view.dart';
import 'package:voice_of_polban/view/draft_view.dart';
import 'package:voice_of_polban/view/settings_view.dart';
import '../auth/auth_controller.dart';
import '../models/app_enums.dart';

class AppSidebar extends StatelessWidget {
  final UserRole currentUserRole;
  const AppSidebar({super.key, required this.currentUserRole});

  static const Color _bg  = Color(0xFF1A1A1A);
  static const Color _card = Color(0xFF232323);
  static const Color _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header profil ──
          Container(
            color: _card,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat Datang,',
                        style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Text('James McGill',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tersimpan ──
          _tile(context, Icons.bookmark_border, 'Tersimpan',
              onTap: () => Navigator.pop(context)),

          // ── Tulis Post (writer only) ──
          if (currentUserRole == UserRole.writer)
            _tile(context, Icons.edit_outlined, 'Tulis Post', onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WriterPage()));
            }),

          // ── Lihat Draft: writer → DraftPage, editor → EditorPage ──
          _tile(context, Icons.inbox_outlined, 'Lihat Draft', onTap: () {
            Navigator.pop(context);
            if (currentUserRole == UserRole.editor) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditorPage()));
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DraftPage()));
            }
          }),

          // ── Pengaturan ──
          _tile(context, Icons.settings_outlined, 'Pengaturan', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  userName: 'James McGill',
                  role: currentUserRole,
                ),
              ),
            );
          }),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Color(0xFF333333), height: 1),
          ),

          // ── Keluar ──
          _tile(context, Icons.logout, 'Keluar', color: _red, onTap: () async {
            Navigator.pop(context);
            final auth = AuthController();
            await auth.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            }
          }),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      {required VoidCallback onTap, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}