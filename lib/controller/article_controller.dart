import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/app_enums.dart';
import '../models/article_model.dart';

class ArticleController {
  final Uuid _uuid = const Uuid();

  // Box references berdasarkan ERD baru
  Box<ArticleModel> get _articlesBox => Hive.box<ArticleModel>('articles_box');
  
  // Asumsi Anda akan membuat Box tambahan untuk Section dan Draft Lokal
  Box get _sectionBox => Hive.box('sections_box');

  // --- READ ENDPOINTS ---

  ArticleModel? getArticle(String articleId) => _articlesBox.get(articleId);

  /// Mengambil artikel berdasarkan Section (Kategori baru di ERD)
  List<ArticleModel> getArticlesBySection(String sectionId) {
    return _articlesBox.values
        .where((article) => article.sectionId == sectionId && article.status == ArticleStatus.published)
        .toList();
  }

  List<ArticleModel> getLatestArticles() {
    return _articlesBox.values
        .where((article) => article.status == ArticleStatus.published)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- WORKFLOW: WRITER (LOCAL_DRAFT) ---

  /// Tahap 1: Simpan ke LOCAL_DRAFT
  /// Sesuai ERD, LOCAL_DRAFT menyimpan draf sebelum sinkronisasi ke tabel ARTICLE utama.
  void saveLocalDraft({
    required String title,
    required String content,
    required String sectionId,
    required String userId,
  }) {
    final String articleId = _uuid.v4();
    
    final newArticle = ArticleModel(
      id: articleId,
      title: title,
      content: content,
      sectionId: sectionId, // Menggunakan section_id dari tabel SECTION
      authorId: userId,
      status: ArticleStatus.draft,
      createdAt: DateTime.now(),
    );
    
    _articlesBox.put(articleId, newArticle);
    // Logika tambahan: Di sini Anda bisa memasukkan payload ke SYNC_QUEUE 
    // untuk sinkronisasi ke Cloud nantinya.
  }

  // --- WORKFLOW: EDITOR (REVISION & REVIEW) ---

  /// Tahap 2 & 3: Keputusan Editor & Histori Revisi
  /// Sesuai tabel REVISION_HISTORY, setiap tindakan editor harus dicatat.
  void reviewArticle({
    required String articleId,
    required String editorId,
    required bool approved,
    String? note,
  }) {
    final article = getArticle(articleId);
    if (article == null) return;

    final newStatus = approved ? ArticleStatus.approved : ArticleStatus.rejected;

    // 1. Update status artikel utama
    _articlesBox.put(
      articleId,
      article.copyWith(
        status: newStatus,
        editorId: editorId, // Mencatat siapa editor yang menangani
        rejectionNote: note,
      ),
    );

    // 2. Simulasi pencatatan ke REVISION_HISTORY (Sesuai ERD)
    _addToRevisionHistory(
      articleId: articleId,
      editorId: editorId,
      action: approved ? 'APPROVE' : 'REJECT',
      note: note ?? '',
    );
  }

  /// Tahap 4: Publikasi
  void publishArticle(String articleId) {
    final article = getArticle(articleId);
    if (article != null && article.status == ArticleStatus.approved) {
      _updateStatus(articleId, ArticleStatus.published);
    }
  }

  // --- INTERNAL UTILS ---

  void _updateStatus(String articleId, ArticleStatus status) {
    final article = _articlesBox.get(articleId);
    if (article == null) return;
    _articlesBox.put(articleId, article.copyWith(status: status));
  }

  /// Helper untuk mencatat histori revisi sesuai ERD
  void _addToRevisionHistory({
    required String articleId,
    required String editorId,
    required String action,
    required String note,
  }) {
    // Di sini Anda akan menyimpan ke Box 'revision_history_box'
    print("Log: Revision saved for $articleId by $editorId: $action - $note");
  }
}

// Helper Extension agar update status lebih bersih
extension on ArticleModel {
  ArticleModel copyWith({
    ArticleStatus? status,
    String? editorId,
    String? rejectionNote,
  }) {
    return ArticleModel(
      id: id,
      title: title,
      content: content,
      sectionId: sectionId,
      authorId: authorId,
      editorId: editorId ?? this.editorId,
      status: status ?? this.status,
      rejectionNote: rejectionNote ?? this.rejectionNote,
      createdAt: createdAt,
    );
  }
}