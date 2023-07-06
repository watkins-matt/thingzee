// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveInventoryAdapter extends TypeAdapter<HiveInventory> {
  @override
  final int typeId = 0;

  @override
  HiveInventory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveInventory()
      ..amount = fields[0] as double
      ..unitCount = fields[1] as int
      ..lastUpdate = fields[2] as DateTime?
      ..expirationDates = (fields[3] as List).cast<DateTime>()
      ..locations = (fields[4] as List).cast<String>()
      ..history = fields[5] as History
      ..restock = fields[6] as bool
      ..upc = fields[7] as String
      ..iuid = fields[8] as String
      ..units = fields[9] as double;
  }

  @override
  void write(BinaryWriter writer, HiveInventory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.unitCount)
      ..writeByte(2)
      ..write(obj.lastUpdate)
      ..writeByte(3)
      ..write(obj.expirationDates)
      ..writeByte(4)
      ..write(obj.locations)
      ..writeByte(5)
      ..write(obj.history)
      ..writeByte(6)
      ..write(obj.restock)
      ..writeByte(7)
      ..write(obj.upc)
      ..writeByte(8)
      ..write(obj.iuid)
      ..writeByte(9)
      ..write(obj.units);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveInventoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
