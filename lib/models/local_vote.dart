import 'package:hive/hive.dart';

part 'local_vote.g.dart';

@HiveType(typeId: 4)
class LocalVote {
  LocalVote({
    required this.voteId,
    required this.postId,
    required this.userId,
    required this.upvoteStatus,
    required this.isSynced,
  });

  @HiveField(0)
  String voteId;

  @HiveField(1)
  String postId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  bool upvoteStatus;

  @HiveField(4)
  bool isSynced;
}
