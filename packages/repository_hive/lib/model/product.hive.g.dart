// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveProductAdapter extends TypeAdapter<HiveProduct> {
  @override
  final int typeId = 0;

  @override
  HiveProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveProduct()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..name = fields[2] as String
      ..uid = fields[3] as String
      ..manufacturer = fields[4] as String
      ..manufacturerUid = fields[5] as String
      ..category = fields[6] as String
      ..upcs = (fields[7] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, HiveProduct obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.uid)
      ..writeByte(4)
      ..write(obj.manufacturer)
      ..writeByte(5)
      ..write(obj.manufacturerUid)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
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
