// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturer.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveManufacturerAdapter extends TypeAdapter<HiveManufacturer> {
  @override
  final int typeId = 1;

  @override
  HiveManufacturer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveManufacturer()
      ..name = fields[0] as String
      ..website = fields[1] as String
      ..muid = fields[2] as String
      ..parentName = fields[3] as String
      ..parentMuid = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, HiveManufacturer obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.website)
      ..writeByte(2)
      ..write(obj.muid)
      ..writeByte(3)
      ..write(obj.parentName)
      ..writeByte(4)
      ..write(obj.parentMuid);
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
