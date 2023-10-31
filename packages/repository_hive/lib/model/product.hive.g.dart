// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveProductAdapter extends TypeAdapter<HiveProduct> {
  @override
  final int typeId = 4;

  @override
  HiveProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveProduct()
      ..name = fields[0] as String
      ..uid = fields[1] as String
      ..manufacturer = fields[2] as String
      ..manufacturerUid = fields[3] as String
      ..category = fields[4] as String
      ..upcs = (fields[5] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, HiveProduct obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.manufacturer)
      ..writeByte(3)
      ..write(obj.manufacturerUid)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.upcs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
