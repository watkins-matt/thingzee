// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturer.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveManufacturerAdapter extends TypeAdapter<HiveManufacturer> {
  @override
  final int typeId = 0;

  @override
  HiveManufacturer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveManufacturer()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..name = fields[2] as String
      ..website = fields[3] as String
      ..uid = fields[4] as String
      ..parentName = fields[5] as String
      ..parentUid = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, HiveManufacturer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.website)
      ..writeByte(4)
      ..write(obj.uid)
      ..writeByte(5)
      ..write(obj.parentName)
      ..writeByte(6)
      ..write(obj.parentUid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveManufacturerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
