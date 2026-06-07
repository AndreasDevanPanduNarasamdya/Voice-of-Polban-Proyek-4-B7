import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../processing/auth_controller.dart';
import '../../processing/studio_controller.dart';
import '../../storage/local_draft.dart';

class WriterPage extends StatefulWidget {
  final String? draftId; // Add this line
  const WriterPage({super.key, this.draftId});

  @override
  State<WriterPage> createState() => _WriterPageState();
}

class _WriterPageState extends State<WriterPage> {
  final AuthController _authController = AuthController();
  final StudioController _studioController = StudioController();
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedImages = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;
  bool _isSubmitting = false;
  LocalDraft? _draft;

  final List<Map<String, String>> _sections = [
    {'id': 'sec_akademik', 'name': 'Akademik'},
    {'id': 'sec_kampus', 'name': 'Kampus'},
    {'id': 'sec_acara', 'name': 'Acara'},
    {'id': 'sec_organisasi', 'name': 'Organisasi'},
  ];

  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    if (widget.draftId != null) {
      // Load existing draft from local Hive box
      _draft = Hive.box<LocalDraft>('local_draft_box').get(widget.draftId);
      if (_draft != null) {
        _titleController.text = _draft!.title;
        _contentController.text = _draft!.content;
        if (_draft!.imageUrls != null) {
          _selectedImages = List<String>.from(
            _draft!.imageUrls!,
          ); // Load offline images
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String? get _currentUserId => _authController.currentUser?.userId;

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 8 gambar!')));
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var img in images) {
            if (_selectedImages.length < 8 &&
                !_selectedImages.contains(img.path)) {
              _selectedImages.add(img.path);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _saveDraft() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final userId = _currentUserId;

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi artikel wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengguna belum login.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      LocalDraft? savedDraft;

      // LOGIC FIX: Check if we are updating an existing draft or creating a new one
      if (_draft != null) {
        savedDraft = await _studioController.updateDraft(
          _draft!.localId,
          title,
          content,
          imageUrls: _selectedImages,
        );
      } else {
        savedDraft = await _studioController.saveDraft(
          title,
          content,
          userId,
          imageUrls: _selectedImages,
        );
      }

      if (!mounted) return;

      setState(() => _draft = savedDraft);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draf tersimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan draf: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitDraft() async {
    if (_draft == null) {
      await _saveDraft();
      if (_draft == null) {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final queueEntry = await _studioController.submitDraft(_draft!.localId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            queueEntry == null
                ? 'Draft tidak ditemukan.'
                : 'Draf dikirim untuk review: ${queueEntry.queueId}.',
          ),
          backgroundColor: queueEntry == null ? Colors.red : Colors.green,
        ),
      );
      if (queueEntry != null) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim draf: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftStatus = _draft?.status.name.toUpperCase();

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
          'VOP',
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
              if (draftStatus != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    'Status draf: $draftStatus',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
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
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Judul',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gambar (${_selectedImages.length}/8)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        InkWell(
                          onTap: _pickImages,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Tambah',
                              style: TextStyle(color: Color(0xFFFF8C00)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final imagePath = _selectedImages[index];
                            final isNetworkImage = imagePath.startsWith('http');
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: isNetworkImage
                                          ? NetworkImage(imagePath)
                                                as ImageProvider
                                          : FileImage(File(imagePath)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                  controller: _contentController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tulis isi artikel di sini...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      'Pilih Kategori',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveDraft,
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
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Draf',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Color(0xFFFF8C00),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitDraft,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    label: Text(
                      _isSubmitting ? 'Mengirim...' : 'Kirim Review',
                      style: const TextStyle(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
