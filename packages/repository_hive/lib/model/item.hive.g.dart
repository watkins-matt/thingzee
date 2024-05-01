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
      ..created = fields[0] as DateTime
      ..updated = fields[1] as DateTime
      ..upc = fields[2] as String
      ..uid = fields[3] as String
      ..name = fields[4] as String
      ..variety = fields[5] as String
      ..category = fields[6] as String
      ..type = fields[7] as String
      ..typeId = fields[8] as String
      ..unitCount = fields[9] as int
      ..unitName = fields[10] as String
      ..unitPlural = fields[11] as String
      ..imageUrl = fields[12] as String
      ..consumable = fields[13] as bool
      ..languageCode = fields[14] as String;
  }

  @override
  void write(BinaryWriter writer, HiveItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.uid)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.variety)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.typeId)
      ..writeByte(9)
      ..write(obj.unitCount)
      ..writeByte(10)
      ..write(obj.unitName)
      ..writeByte(11)
      ..write(obj.unitPlural)
      ..writeByte(12)
      ..write(obj.imageUrl)
      ..writeByte(13)
      ..write(obj.consumable)
      ..writeByte(14)
      ..write(obj.languageCode);
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
