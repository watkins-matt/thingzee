// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveItemAdapter extends TypeAdapter<HiveItem> {
  @override
  final int typeId = 0;

  @override
  HiveItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveItem()
      ..upc = fields[4] as String
      ..uid = fields[5] as String
      ..name = fields[6] as String
      ..variety = fields[7] as String
      ..category = fields[8] as String
      ..type = fields[9] as String
      ..typeId = fields[10] as String
      ..unitCount = fields[11] as int
      ..unitName = fields[12] as String
      ..unitPlural = fields[13] as String
      ..imageUrl = fields[14] as String
      ..consumable = fields[15] as bool
      ..languageCode = fields[16] as String
      ..lastUpdate = fields[17] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(4)
      ..write(obj.upc)
      ..writeByte(5)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.name)
      ..writeByte(7)
      ..write(obj.variety)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.typeId)
      ..writeByte(11)
      ..write(obj.unitCount)
      ..writeByte(12)
      ..write(obj.unitName)
      ..writeByte(13)
      ..write(obj.unitPlural)
      ..writeByte(14)
      ..write(obj.imageUrl)
      ..writeByte(15)
      ..write(obj.consumable)
      ..writeByte(16)
      ..write(obj.languageCode)
      ..writeByte(17)
      ..write(obj.lastUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      ..upc = fields[0] as String
      ..languageCode = fields[1] as String
      ..name = fields[2] as String
      ..variety = fields[3] as String
      ..unitName = fields[4] as String
      ..unitPlural = fields[5] as String
      ..type = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, HiveItemTranslation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.upc)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.variety)
      ..writeByte(4)
      ..write(obj.unitName)
      ..writeByte(5)
      ..write(obj.unitPlural)
      ..writeByte(6)
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
