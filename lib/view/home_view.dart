import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/article_view.dart';

class HomePage extends StatefulWidget {
  // final LocalData local;
  const HomePage({super.key /*,required this.local*/});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("HEADER"),
        centerTitle: true,
        actions: const [Icon(Icons.account_circle), SizedBox(width: 16)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPlaceholderCard(context),
          const SizedBox(height: 16),
          _buildPlaceholderCard(context),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.language, size: 40), //Kategori Umum
            Icon(Icons.emoji_events_sharp, size: 40), // Kategori Lomba
            Icon(Icons.event, size: 40), //Kategori Event
            Icon(Icons.group, size: 40), //Kategori Ormawa
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArticlePage()),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text("GAMBAR"),
                ),
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text("JUDUL"),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text("DESKRIPSI"),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
