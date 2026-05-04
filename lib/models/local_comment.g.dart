// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_comment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalCommentAdapter extends TypeAdapter<LocalComment> {
  @override
  final int typeId = 5;

  @override
  LocalComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalComment(
      commentId: fields[0] as String,
      postId: fields[1] as String,
      userId: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isSynced: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalComment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.commentId)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
