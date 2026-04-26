// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 4;

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

class ArticleStatusAdapter extends TypeAdapter<ArticleStatus> {
  @override
  final int typeId = 5;

  @override
  ArticleStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArticleStatus.draft;
      case 1:
        return ArticleStatus.pending;
      case 2:
        return ArticleStatus.approved;
      case 3:
        return ArticleStatus.published;
      case 4:
        return ArticleStatus.rejected;
      case 5:
        return ArticleStatus.archived;
      default:
        return ArticleStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, ArticleStatus obj) {
    switch (obj) {
      case ArticleStatus.draft:
        writer.writeByte(0);
        break;
      case ArticleStatus.pending:
        writer.writeByte(1);
        break;
      case ArticleStatus.approved:
        writer.writeByte(2);
        break;
      case ArticleStatus.published:
        writer.writeByte(3);
        break;
      case ArticleStatus.rejected:
        writer.writeByte(4);
        break;
      case ArticleStatus.archived:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
