import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/app_enums.dart';
import '../models/article_model.dart';

class ArticleController {
  static const int _latestArticlesLimit = 5;
  final Uuid _uuid = const Uuid();

  // Getter untuk mengakses box Hive yang telah diinisialisasi di hive_setup
  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('articles_box');

  // --- READ ENDPOINTS ---

  /// Mengambil data artikel spesifik berdasarkan ID
  ArticleModel? getArticle(String articleId) => _articlesBox.get(articleId);

  /// Menampilkan daftar berita yang sudah Published untuk user (Tahap 4)
  List<ArticleModel> getPublishedArticles() {
    return _articlesBox.values
        .where((article) => article.status == ArticleStatus.published)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Dashboard untuk Editor: Mengambil artikel dengan status Pending
  List<ArticleModel> getPendingArticles() {
    return _articlesBox.values
        .where((article) => article.status == ArticleStatus.pending)
        .toList();
  }

  // Digunakan oleh HomePage untuk mengambil berita terbaru yang sudah terbit
  List<ArticleModel> getLatestArticles() {
    return _articlesBox.values
        // 1. Filter: Hanya ambil yang statusnya sudah 'published'
        .where((article) => article.status == ArticleStatus.published)
        .toList()
      // 2. Sort: Urutkan berdasarkan tanggal (Terbaru di atas)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- WRITE & WORKFLOW ENDPOINTS ---

  /// Tahap 1: Penulisan Draf (Hybrid/Offline)
  /// Menyimpan draf ke database lokal Hive dengan status awal Draft.
  void saveDraft({
    required String title,
    required String content,
    required ArticleCategory category,
    required String authorId,
  }) {
    final String articleId = _uuid.v4();
    final newArticle = ArticleModel(
      id: articleId,
      title: title,
      content: content,
      category: category,
      authorId: authorId,
      status: ArticleStatus.draft,
      createdAt: DateTime.now(),
    );
    _articlesBox.put(articleId, newArticle);
  }

  /// Tahap 2: Review Editor (Submit)
  /// Mengubah status draf menjadi Pending agar muncul di dashboard Editor.
  void submitForReview(String articleId) {
    _updateStatus(articleId, ArticleStatus.pending);
  }

  /// Tahap 3: Keputusan Editor - Reject
  /// Mengembalikan berita ke Writer dengan catatan revisi (rejectionNote).
  void rejectArticle(String articleId, String reason) {
    _updateStatus(
      articleId,
      ArticleStatus.rejected,
      note: reason,
    );
  }

  void updateArticle({
  required String articleId,
  required String title,
  required String content,
  required ArticleCategory category,
  }) {
    final article = getArticle(articleId);
    if (article == null) return;

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: title,
        content: content,
        category: category,
        authorId: article.authorId,
        status: ArticleStatus.draft, // Kembali ke draf saat diedit
        createdAt: article.createdAt,
        rejectionNote: null, // Hapus catatan lama karena sudah direvisi
      ),
    );
  }

  /// Tahap 3: Keputusan Editor - Approve
  /// Menyetujui artikel sehingga siap untuk dipublikasikan.
  void approveArticle(String articleId) {
    _updateStatus(articleId, ArticleStatus.approved);
  }

  /// Tahap 4: Publikasi & Distribusi
  /// Mengubah status menjadi Published untuk didistribusikan ke pembaca.
  void publishArticle(String articleId) {
    final article = getArticle(articleId);
    // Validasi: Hanya artikel yang sudah Approved yang bisa dipublikasikan
    if (article != null && article.status == ArticleStatus.approved) {
      _updateStatus(articleId, ArticleStatus.published);
    }
  }

  // --- INTERNAL UTILS ---

  /// Fungsi internal untuk update status dan mempertahankan data lainnya
  void _updateStatus(String articleId, ArticleStatus status, {String? note}) {
    final article = _articlesBox.get(articleId);
    if (article == null) return;

    _articlesBox.put(
      articleId,
      ArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        category: article.category,
        authorId: article.authorId,
        status: status,
        rejectionNote: note ?? article.rejectionNote,
        createdAt: article.createdAt,
      ),
    );
  }

  /// Menghapus data artikel dari Hive
  void deleteArticle(String articleId) => _articlesBox.delete(articleId);
}