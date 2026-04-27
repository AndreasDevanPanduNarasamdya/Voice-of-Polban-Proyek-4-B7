import 'package:flutter/material.dart';

class WriterPage extends StatefulWidget {
  const WriterPage({super.key});

  @override
  State<WriterPage> createState() => _WriterPageState();
}

class _WriterPageState extends State<WriterPage> {
  static const Color _bgColor = Color(0xFF1A1A2E);
  static const Color _cardColor = Color(0xFF16213E);
  static const Color _accentColor = Color(0xFF0F3460);
  static const Color _highlightColor = Color(0xFFE94560);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedCategory;
  String? _frontImagePath;
  String? _contentImagePath;

  final List<String> _categories = ['Umum', 'Lomba', 'Event', 'Ormawa'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: _accentColor.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accentColor.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accentColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _highlightColor, width: 1.5),
        ),
      );

  Widget _imagePicker(String label, String? path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accentColor.withOpacity(0.5)),
        ),
        child: path != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(path, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: Colors.white38, size: 36),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _highlightColor.withOpacity(0.5)),
                    ),
                    child: Text(label,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: _highlightColor, shape: BoxShape.circle),
              child: const Icon(Icons.campaign, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text('Voice of Polban',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Judul field
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Masukkan Judul'),
            ),
            const SizedBox(height: 16),

            // Gambar depan
            _imagePicker('Tambah Gambar Depan', _frontImagePath, () {
              // TODO: implementasi image picker
            }),
            const SizedBox(height: 16),

            // Isi artikel
            TextField(
              controller: _contentController,
              maxLines: 7,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Tambah Isi').copyWith(
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _highlightColor.withOpacity(0.4)),
                ),
                child: const Text('Pratinjau Isi',
                    style: TextStyle(color: _highlightColor, fontSize: 11)),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: _cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('').copyWith(
                hintText: null,
                labelText: 'Kategori',
                labelStyle: const TextStyle(color: Colors.white54),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 28),

            // Tombol Submit
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: submit artikel
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artikel berhasil dikirim!'),
                      backgroundColor: Color(0xFF0F3460),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _highlightColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Submit',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}