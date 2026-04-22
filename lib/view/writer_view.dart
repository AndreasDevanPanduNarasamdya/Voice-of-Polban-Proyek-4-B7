import 'dart:io';
import 'package:flutter/material.dart';

class WriterPage extends StatefulWidget {
  // final LocalData local;
  const WriterPage({super.key /*,required this.local*/});

  @override
  State<WriterPage> createState() => _WriterPage();
}

class _WriterPage extends State<WriterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HEADER"), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TextField(decoration: InputDecoration(labelText: "JUDUL")),
              const SizedBox(height: 20),

              const TextField(
                decoration: InputDecoration(labelText: "DESKRIPSI"),
              ),
              const SizedBox(height: 20),

              Container(
                height: 200,
                decoration: BoxDecoration(border: Border.all()),
                alignment: Alignment.center,
                child: const Text("GAMBAR"),
              ),
              const SizedBox(height: 20),

              const TextField(
                maxLines: 8,
                decoration: InputDecoration(labelText: "TEKS"),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                items: const [],
                onChanged: null,
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
