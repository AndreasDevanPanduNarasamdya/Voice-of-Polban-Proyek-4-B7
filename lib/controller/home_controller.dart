import 'package:hive/hive.dart';
import '../models/article_model.dart';

class HomeController {
  List<ArticleModel> loadFeedData() {
    print("Fetching real home feed data from Hive...");

    final box = Hive.box<ArticleModel>('articles_box');

    return box.values.toList();
  }
}
