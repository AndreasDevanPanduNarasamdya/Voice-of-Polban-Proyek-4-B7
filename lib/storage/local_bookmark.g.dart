// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_bookmark.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalBookmarkAdapter extends TypeAdapter<LocalBookmark> {
  @override
  final int typeId = 6;

  @override
  LocalBookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalBookmark(
      bookmarkId: fields[0] as String,
      postId: fields[1] as String,
      userId: fields[2] as String,
      isSynced: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalBookmark obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bookmarkId)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalBookmarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
