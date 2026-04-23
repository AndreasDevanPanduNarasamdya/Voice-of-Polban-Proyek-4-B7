class HomeController {
  List<Map<String, String>> loadFeedData() {
    print("Fetching home feed data...");

    return [
      {
        "judul": "Aplikasi MetroPolban Rilis!",
        "deskripsi":
            "Aplikasi berita kampus terbaru resmi diluncurkan hari ini.",
        "gambar": "GAMBAR ARTIKEL 1",
      },
      {
        "judul": "Tips Bertahan di Polban",
        "deskripsi": "Panduan ngerjain tugas akhir tanpa kurang tidur.",
        "gambar": "GAMBAR ARTIKEL 2",
      },
    ];
  }
}
