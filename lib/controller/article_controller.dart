class ArticleController {
  // This is your unpacking/loading algorithm.
  // Later, this will be an async function that grabs JSON from your backend.
  Map<String, String> loadArticleData() {
    print("Fetching article data...");

    // Placeholder data acting as your database response
    return {
      "judul": "Berita Utama MetroPolban",
      "deskripsi":
          "Liputan khusus mengenai perkembangan sistem baru di lingkungan kampus.",
      "penulis": "Tim Jurnalis",
      "gambar": "GAMBAR PLACEHOLDER",
      "teks":
          "Ini adalah teks isi artikel. Bayangkan ini berisi banyak paragraf penting. \n\nSemua data ini di-load langsung dari controller, bukan ditulis mati (hardcode) di dalam View!",
    };
  }
}
