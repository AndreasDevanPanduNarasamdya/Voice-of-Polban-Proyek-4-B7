import 'package:flutter/material.dart';

// Config Layer
import '../../config/app_enums.dart';

// Processing Layer
import '../../processing/auth_controller.dart';

// UI Layer (Screens)
import '../screens/login_view.dart'; // Replaces the old auth_view.dart
import '../screens/writer_view.dart';
import '../screens/editor_view.dart';
import '../screens/draft_view.dart';
import '../screens/settings_view.dart';

class AppSidebar extends StatelessWidget {
  final UserRole currentUserRole;
  const AppSidebar({super.key, required this.currentUserRole});

  static const Color _bg = Color(0xFF1A1A1A);
  static const Color _card = Color(0xFF232323);
  static const Color _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final user = AuthController().currentUser;
    final userName = user?.name ?? 'Pengguna';
    final avatarUrl = user?.avatarUrl ?? '';

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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 28,
                        )
                      : null,
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tersimpan ──
          _tile(
            context,
            Icons.bookmark_border,
            'Tersimpan',
            onTap: () => Navigator.pop(context),
          ),

          // ── Tulis Post (writer only) ──
          if (currentUserRole == UserRole.writer)
            _tile(
              context,
              Icons.edit_outlined,
              'Tulis Post',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WriterPage()),
                );
              },
            ),

          // ── Lihat Draft: writer → DraftPage, editor → EditorPage ──
          if (currentUserRole == UserRole.writer ||
              currentUserRole == UserRole.editor)
            _tile(
              context,
              Icons.inbox_outlined,
              'Lihat Draft',
              onTap: () {
                Navigator.pop(context);
                if (currentUserRole == UserRole.editor) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditorPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DraftPage()),
                  );
                }
              },
            ),

          // ── Pengaturan ──
          _tile(
            context,
            Icons.settings_outlined,
            'Pengaturan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsPage(userName: userName, role: currentUserRole),
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Color(0xFF333333), height: 1),
          ),

          // ── Keluar ──
          _tile(
            context,
            Icons.logout,
            'Keluar',
            color: _red,
            onTap: () async {
              Navigator.pop(context);
              final auth = AuthController();
              auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
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
