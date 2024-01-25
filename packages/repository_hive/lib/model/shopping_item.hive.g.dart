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
      ..upc = fields[2] as String
      ..checked = fields[3] as bool
      ..listType = fields[4] as ShoppingListType;
  }

  @override
  void write(BinaryWriter writer, HiveShoppingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.upc)
      ..writeByte(3)
      ..write(obj.checked)
      ..writeByte(4)
      ..write(obj.listType);
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
