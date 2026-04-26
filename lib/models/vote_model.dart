import 'package:hive/hive.dart';

part 'vote_model.g.dart';

@HiveType(typeId: 8)
class VoteModel {
  const VoteModel({
    required this.voteId,
    required this.upvoteStatus,
    required this.articleId,
    required this.userId,
    required this.isSynced,
  });

  @HiveField(0)
  final String voteId;

  @HiveField(1)
  final bool upvoteStatus;

  @HiveField(2)
  final String articleId;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final bool isSynced;
}
