// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 8;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.reader;
      case 1:
        return UserRole.writer;
      case 2:
        return UserRole.editor;
      default:
        return UserRole.reader;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.reader:
        writer.writeByte(0);
        break;
      case UserRole.writer:
        writer.writeByte(1);
        break;
      case UserRole.editor:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostStatusAdapter extends TypeAdapter<PostStatus> {
  @override
  final int typeId = 9;

  @override
  PostStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PostStatus.draft;
      case 1:
        return PostStatus.pending;
      case 2:
        return PostStatus.approved;
      case 3:
        return PostStatus.rejected;
      case 4:
        return PostStatus.published;
      case 5:
        return PostStatus.archived;
      case 6:
        return PostStatus.dropped;
      default:
        return PostStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, PostStatus obj) {
    switch (obj) {
      case PostStatus.draft:
        writer.writeByte(0);
        break;
      case PostStatus.pending:
        writer.writeByte(1);
        break;
      case PostStatus.approved:
        writer.writeByte(2);
        break;
      case PostStatus.rejected:
        writer.writeByte(3);
        break;
      case PostStatus.published:
        writer.writeByte(4);
        break;
      case PostStatus.archived:
        writer.writeByte(5);
        break;
      case PostStatus.dropped:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
