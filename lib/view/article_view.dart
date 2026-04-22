import 'dart:io';
import 'package:flutter/material.dart';

class ArticlePage extends StatefulWidget {
  // final LocalData local;
  const ArticlePage({super.key /*,required this.local*/});

  @override
  State<ArticlePage> createState() => _ArticlePage();
}

class _ArticlePage extends State<ArticlePage> {
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
          const Text(
            "Judul Artikel",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),

          const Text(
            "Deskripsi Artikel",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 19),
          ),
          const SizedBox(height: 16),

          const Text("Nama Penulis Artikel", textAlign: TextAlign.left),
          const SizedBox(height: 24),

          Container(
            height: 250,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
            ),
            child: const Text("GAMBAR", style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 24),

          const Text(
            "Teks Isi Artikel",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
