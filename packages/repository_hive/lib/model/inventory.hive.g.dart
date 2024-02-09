// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveInventoryAdapter extends TypeAdapter<HiveInventory> {
  @override
  final int typeId = 0;

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveInventoryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;

  @override
  HiveInventory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveInventory()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..amount = fields[2] as double
      ..unitCount = fields[3] as int
      ..locations = (fields[4] as List).cast<String>()
      ..expirationDates = (fields[5] as List).cast<DateTime>()
      ..restock = fields[6] as bool
      ..uid = fields[7] as String
      ..upc = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, HiveInventory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.unitCount)
      ..writeByte(4)
      ..write(obj.locations)
      ..writeByte(5)
      ..write(obj.expirationDates)
      ..writeByte(6)
      ..write(obj.restock)
      ..writeByte(7)
      ..write(obj.uid);
  }
}
