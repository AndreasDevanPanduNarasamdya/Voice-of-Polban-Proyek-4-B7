// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueAdapter extends TypeAdapter<SyncQueue> {
  @override
  final int typeId = 3;

  @override
  SyncQueue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueue(
      queueId: fields[0] as String,
      actionType: fields[1] as String,
      payload: fields[2] as String,
      isProcessed: fields[3] as bool,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueue obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.queueId)
      ..writeByte(1)
      ..write(obj.actionType)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.isProcessed)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
