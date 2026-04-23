import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voice_of_polban/view/article_view.dart';
import 'package:voice_of_polban/controller/home_controller.dart';

class HomePage extends StatefulWidget {
  // final LocalData local;
  const HomePage({super.key /*,required this.local*/});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final HomeController _controller = HomeController();
  late List<Map<String, String>> _feedData;

  @override
  void initState() {
    super.initState();
    _feedData = _controller.loadFeedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("HEADER"),
        centerTitle: true,
        actions: const [Icon(Icons.account_circle), SizedBox(width: 16)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _feedData.length,
        itemBuilder: (context, index) {
          final articleData = _feedData[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPlaceholderCard(context, articleData),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
            Icon(Icons.circle, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, Map<String, String> data) {
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
                  child: Text(data["gambar"] ?? "GAMBAR"),
                ),
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    data["judul"] ?? "JUDUL",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(data["deskripsi"] ?? "DESKRIPSI"),
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
