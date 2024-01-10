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
      ..upc = fields[0] as String
      ..checked = fields[1] as bool
      ..listType = fields[2] as ShoppingListType;
  }

  @override
  void write(BinaryWriter writer, HiveShoppingItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.upc)
      ..writeByte(1)
      ..write(obj.checked)
      ..writeByte(2)
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
