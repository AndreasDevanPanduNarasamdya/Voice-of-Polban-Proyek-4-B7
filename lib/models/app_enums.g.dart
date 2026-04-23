// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 1;

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
  final int typeId = 2;

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
        return ArticleStatus.rejected;
      case 4:
        return ArticleStatus.published;
      case 5:
        return ArticleStatus.archived;
      case 6:
        return ArticleStatus.dropped;
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
      case ArticleStatus.rejected:
        writer.writeByte(3);
        break;
      case ArticleStatus.published:
        writer.writeByte(4);
        break;
      case ArticleStatus.archived:
        writer.writeByte(5);
        break;
      case ArticleStatus.dropped:
        writer.writeByte(6);
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

class ArticleCategoryAdapter extends TypeAdapter<ArticleCategory> {
  @override
  final int typeId = 3;

  @override
  ArticleCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArticleCategory.akademik;
      case 1:
        return ArticleCategory.beritaKampus;
      case 2:
        return ArticleCategory.acara;
      case 3:
        return ArticleCategory.ormawa;
      default:
        return ArticleCategory.akademik;
    }
  }

  @override
  void write(BinaryWriter writer, ArticleCategory obj) {
    switch (obj) {
      case ArticleCategory.akademik:
        writer.writeByte(0);
        break;
      case ArticleCategory.beritaKampus:
        writer.writeByte(1);
        break;
      case ArticleCategory.acara:
        writer.writeByte(2);
        break;
      case ArticleCategory.ormawa:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
