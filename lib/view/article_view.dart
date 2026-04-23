import 'dart:io';
import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../controller/article_controller.dart';

class ArticlePage extends StatefulWidget {
  final String articleId;
  const ArticlePage({super.key, required this.articleId});

  @override
  State<ArticlePage> createState() => _ArticlePage();
}

class _ArticlePage extends State<ArticlePage> {
  final ArticleController _controller = ArticleController();
  ArticleModel? _articleData;

  @override
  void initState() {
    super.initState();
    _articleData = _controller.getArticle(widget.articleId);
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
      // THE NEW CHECK: If the article was deleted, show a simple text message.
      // Otherwise (the : symbol), draw your exact ListView!
      body: _articleData == null
          ? const Center(
              child: Text("Artikel tidak ditemukan atau telah dihapus."),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  // CHANGED: ["judul"] becomes .title
                  _articleData!.title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),

                Text(
                  // CHANGED: Swapped deskripsi for the category name!
                  "Kategori: ${_articleData!.category.name}",
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 19),
                ),
                const SizedBox(height: 16),

                Text(
                  // CHANGED: ["penulis"] becomes .authorId
                  "Penulis: ${_articleData!.authorId}",
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),

                Container(
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text(
                    // CHANGED: Since your model doesn't have an image field yet,
                    // we just hardcode the placeholder text for now.
                    "GAMBAR",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  // CHANGED: ["teks"] becomes .content
                  _articleData!.content,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
    );
  }
}
