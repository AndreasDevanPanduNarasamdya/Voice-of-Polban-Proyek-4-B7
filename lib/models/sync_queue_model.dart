import 'package:hive/hive.dart';

part 'sync_queue_model.g.dart';

@HiveType(typeId: 12)
class SyncQueueModel {
  const SyncQueueModel({
    required this.queueId,
    required this.userId,
    required this.actionType,
    required this.payload,
    required this.isProcessed,
  });

  @HiveField(0)
  final String queueId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String actionType;

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final bool isProcessed;
}
