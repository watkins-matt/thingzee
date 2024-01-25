// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveReceiptItemAdapter extends TypeAdapter<HiveReceiptItem> {
  @override
  final int typeId = 0;

  @override
  HiveReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveReceiptItem()
      ..created = fields[0] as DateTime?
      ..updated = fields[1] as DateTime?
      ..name = fields[2] as String
      ..price = fields[3] as double
      ..regularPrice = fields[4] as double
      ..quantity = fields[5] as int
      ..barcode = fields[6] as String
      ..taxable = fields[7] as bool
      ..bottleDeposit = fields[8] as double;
  }

  @override
  void write(BinaryWriter writer, HiveReceiptItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.created)
      ..writeByte(1)
      ..write(obj.updated)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.regularPrice)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.barcode)
      ..writeByte(7)
      ..write(obj.taxable)
      ..writeByte(8)
      ..write(obj.bottleDeposit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
