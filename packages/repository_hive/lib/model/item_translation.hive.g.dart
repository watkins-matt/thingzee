// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_translation.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveItemTranslationAdapter extends TypeAdapter<HiveItemTranslation> {
  @override
  final int typeId = 0;

  @override
  HiveItemTranslation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveItemTranslation()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..upc = fields[2] as String
      ..languageCode = fields[3] as String
      ..name = fields[4] as String
      ..variety = fields[5] as String
      ..unitName = fields[6] as String
      ..unitPlural = fields[7] as String
      ..type = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, HiveItemTranslation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.languageCode)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.variety)
      ..writeByte(6)
      ..write(obj.unitName)
      ..writeByte(7)
      ..write(obj.unitPlural)
      ..writeByte(8)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveItemTranslationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
