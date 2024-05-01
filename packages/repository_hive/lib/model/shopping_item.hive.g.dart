// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveShoppingItemAdapter extends TypeAdapter<HiveShoppingItem> {
  @override
  final int typeId = 0;

  @override
  HiveShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveShoppingItem()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..uid = fields[2] as String
      ..upc = fields[3] as String
      ..name = fields[4] as String
      ..category = fields[5] as String
      ..price = fields[6] as double
      ..quantity = fields[7] as int
      ..checked = fields[8] as bool
      ..listName = fields[9] as String;
  }

  @override
  void write(BinaryWriter writer, HiveShoppingItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.uid)
      ..writeByte(3)
      ..write(obj.upc)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.checked)
      ..writeByte(9)
      ..write(obj.listName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveShoppingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
