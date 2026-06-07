import 'package:flutter/material.dart';
import 'package:voice_of_polban/ui/screens/login_view.dart';
import 'package:voice_of_polban/processing/auth_controller.dart';
import 'package:voice_of_polban/ui/screens/editor_view.dart';
import 'package:voice_of_polban/ui/screens/draft_view.dart';
import 'package:voice_of_polban/ui/screens/settings_view.dart';
import '../../config/app_enums.dart';

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
          // ── Header Profil ──
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
                  backgroundColor: Colors.grey[800],
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Menu Tersimpan ──
          _tile(
            context,
            Icons.bookmark_border,
            'Tersimpan',
            onTap: () => Navigator.pop(context),
          ),

          // ── Menu Kelola Artikel (Pengganti Lihat Draft, Tanpa Tombol Tulis di Sini) ──
          if (currentUserRole == UserRole.writer ||
              currentUserRole == UserRole.editor)
            _tile(
              context,
              Icons.article_outlined,
              'Kelola Artikel',
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

          // ── Menu Pengaturan ──
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

          // ── Menu Keluar ──
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
