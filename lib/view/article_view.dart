import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/article_controller.dart';

class ArticlePage extends StatefulWidget {
  // final LocalData local;
  const ArticlePage({super.key /*,required this.local*/});

  @override
  State<ArticlePage> createState() => _ArticlePage();
}

class _ArticlePage extends State<ArticlePage> {
  final ArticleController _controller = ArticleController();
  late Map<String, String> _articleData;

  @override
  void initState() {
    super.initState();
    _articleData = _controller.loadArticleData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("HEADER"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            _articleData["judul"] ?? "Judul Tidak Tersedia",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),

          Text(
            _articleData["deskripsi"] ?? "Deskripsi Tidak Tersedia",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 19),
          ),
          const SizedBox(height: 16),

          Text(
            _articleData["penulis"] ?? "Penulis Tidak Diketahui",
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),

          Container(
            height: 250,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              _articleData["gambar"] ?? "GAMBAR",
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            _articleData["teks"] ?? "Isi teks tidak tersedia.",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
