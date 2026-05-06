import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controller/article_controller.dart';
import '../auth/auth_service.dart';

class WriterPage extends StatefulWidget {
  const WriterPage({super.key});

  @override
  State<WriterPage> createState() => _WriterPageState();
}

class _WriterPageState extends State<WriterPage> {
  // 1. Core Architecture Integrations
  final AuthService _authService = AuthService();
  late final ArticleController _articleController;

  // 2. Form State Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedSectionId;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // 3. Mock Sections (Usually fetched from a SectionBox in Hive)
  final List<Map<String, String>> _sections = [
    {'id': 'sec_akademik', 'name': 'Akademik'},
    {'id': 'sec_kampus', 'name': 'Kampus'},
    {'id': 'sec_acara', 'name': 'Acara'},
    {'id': 'sec_organisasi', 'name': 'Organisasi'},
  ];

  @override
  void initState() {
    super.initState();
    // Inject the Auth Service into the Article Controller
    _articleController = ArticleController(authService: _authService);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    }
  }

  void _submitDraft() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validation
    if (title.isEmpty || content.isEmpty || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul, Isi, dan Kategori wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Call the Domain Controller with image
    _articleController.createDraft(
      title: title,
      content: content,
      sectionId: _selectedSectionId!,
      imageFile: _selectedImage,
    );

    // Give UX feedback and return to feed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Draf berhasil disimpan!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VOP",
          style: TextStyle(
            color: Color(0xFF000080),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- TITLE FIELD ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController, // Bound to controller
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Masukkan Judul",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- IMAGE UPLOAD (Functional) ---
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage == null
                    ? InkWell(
                        onTap: _pickImage,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tambah Gambar Depan",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Pilih Gambar",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // --- CONTENT FIELD (Fixed UI/UX) ---
              Container(
                height: 250,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _contentController, // Bound to controller
                  maxLines: null, // Allows multiline wrapping
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText:
                        "Tulis isi artikel di sini...", // Fixed overlapping UX
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- CATEGORY DROPDOWN (Now Dynamic!) ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    isExpanded: true,
                    value: _selectedSectionId,
                    hint: const Text(
                      "Pilih Kategori",
                      style: TextStyle(color: Colors.white),
                    ),
                    items: _sections.map((section) {
                      return DropdownMenuItem<String>(
                        value: section['id'],
                        child: Text(
                          section['name']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSectionId = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- SUBMIT BUTTON ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _submitDraft, // Trigger the submission
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: const Text(
                    "Submit ke draf",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Color(0xFFFF8C00),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
