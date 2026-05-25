import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_enums.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_view.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  final String? userImageUrl;
  final UserRole role;

  const SettingsPage({
    super.key,
    required this.userName,
    required this.role,
    this.userImageUrl,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _bg = Color(0xFF1A1A1A);
  static const Color _card = Color(0xFF232323);
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _red = Color(0xFFE53935);

  final AuthController _auth = AuthController();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.userImageUrl ?? _auth.currentUser?.avatarUrl;
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final success = await _auth.updateProfilePicture(picked.path);
    if (!mounted) return;

    if (success) {
      setState(() {
        _avatarUrl = _auth.currentUser?.avatarUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui foto.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[800],
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
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
                  radius: 32,
                  backgroundColor: Colors.grey[700],
                  backgroundImage:
                      (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role == UserRole.writer
                          ? 'Penulis'
                          : widget.role == UserRole.editor
                          ? 'Editor'
                          : 'Pembaca',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu utama
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _item(
                  Icons.account_circle_outlined,
                  'Ubah foto profil',
                  _pickAndUploadAvatar,
                ),
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
              color: _card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _item(
                  Icons.logout,
                  'Keluar',
                  () => _confirm(
                    context,
                    title: 'Keluar',
                    msg: 'Apakah kamu yakin ingin keluar?',
                    btnLabel: 'Keluar',
                    onOk: () async {
                      _auth.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  color: _red,
                ),

                if (widget.role == UserRole.writer) ...[
                  _line(),
                  _item(
                    Icons.delete_outline,
                    'Hapus akun',
                    () => _confirm(
                      context,
                      title: 'Hapus Akun',
                      msg: 'Akun kamu akan dihapus permanen. Lanjutkan?',
                      btnLabel: 'Hapus',
                      onOk: () => Navigator.popUntil(context, (r) => r.isFirst),
                    ),
                    color: _red,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: color, fontSize: 15)),
        ],
      ),
    ),
  );

  Widget _line() => const Divider(
    height: 1,
    indent: 56,
    endIndent: 16,
    color: Color(0xFF3A3A3A),
  );

  void _confirm(
    BuildContext context, {
    required String title,
    required String msg,
    required String btnLabel,
    required VoidCallback onOk,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk();
            },
            child: Text(
              btnLabel,
              style: const TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}
