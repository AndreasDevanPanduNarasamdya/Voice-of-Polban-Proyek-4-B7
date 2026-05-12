// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_draft.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalDraftAdapter extends TypeAdapter<LocalDraft> {
  @override
  final int typeId = 1;

  @override
  LocalDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalDraft(
      localId: fields[0] as String,
      postId: fields[1] as String,
      userId: fields[2] as String,
      title: fields[3] as String,
      content: fields[4] as String,
      status: fields[5] as PostStatus,
      updatedAt: fields[6] as DateTime,
      rejectionNote: fields[7] as String?,
      imageUrls: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalDraft obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.rejectionNote)
      ..writeByte(8)
      ..write(obj.imageUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
