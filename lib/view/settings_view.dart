import 'package:flutter/material.dart';
import '../models/app_enums.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_view.dart'; // To navigate back to login

class SettingsPage extends StatelessWidget {
  final String userName;
  final String? userImageUrl;
  final UserRole role;

  const SettingsPage({
    super.key,
    required this.userName,
    required this.role,
    this.userImageUrl,
  });

  static const Color _bg       = Color(0xFF1A1A1A);
  static const Color _card     = Color(0xFF232323);
  static const Color _orange   = Color(0xFFFF6D00);
  static const Color _red      = Color(0xFFE53935);
  static const Color _divider  = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _orange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pengaturan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[800],
              backgroundImage:
                  userImageUrl != null ? NetworkImage(userImageUrl!) : null,
              child: userImageUrl == null
                  ? const Icon(Icons.person, color: Colors.white70, size: 20)
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header profil
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[700],
                  backgroundImage:
                      userImageUrl != null ? NetworkImage(userImageUrl!) : null,
                  child: userImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white70, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat Datang,',
                        style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Text(userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Menu utama
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _item(Icons.account_circle_outlined, 'Ubah foto profil', () {}),
                _line(),
                _item(Icons.edit_outlined, 'Ubah nama', () {}),
                _line(),
                _item(Icons.info_outlined, 'Baca ketentuan', () {}),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Menu bahaya
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _item(Icons.logout, 'Keluar', () => _confirm(context,
                  title: 'Keluar',
                  msg: 'Apakah kamu yakin ingin keluar?',
                  btnLabel: 'Keluar',
                  onOk: () async {
                    // LOGIC FIX: Actually wipe the session data!
                    final auth = AuthController();
                    await auth.logout(); 
                    
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (route) => false,
                      );
                    }
                  },
                ), color: _red),

                // Hapus akun hanya untuk writer
                if (role == UserRole.writer) ...[
                  _line(),
                  _item(Icons.delete_outline, 'Hapus akun', () => _confirm(context,
                    title: 'Hapus Akun',
                    msg: 'Akun kamu akan dihapus permanen. Lanjutkan?',
                    btnLabel: 'Hapus',
                    onOk: () => Navigator.popUntil(context, (r) => r.isFirst),
                  ), color: _red),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.white}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 15)),
          ]),
        ),
      );

  Widget _line() => const Divider(height: 1, indent: 56, endIndent: 16,
      color: Color(0xFF3A3A3A));

  void _confirm(BuildContext context,
      {required String title,
      required String msg,
      required String btnLabel,
      required VoidCallback onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () { Navigator.pop(context); onOk(); },
              child: Text(btnLabel,
                  style: const TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
  }
}