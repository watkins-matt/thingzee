// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) => ReceiptItem(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      regularPrice: (json['regularPrice'] as num?)?.toDouble() ?? 0.0,
      barcode: json['barcode'] as String? ?? '',
      taxable: json['taxable'] as bool? ?? true,
      bottleDeposit: (json['bottleDeposit'] as num?)?.toDouble() ?? 0.0,
      receiptUid: json['receiptUid'] as String? ?? '',
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ReceiptItemToJson(ReceiptItem instance) =>
    <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'name': instance.name,
      'price': instance.price,
      'regularPrice': instance.regularPrice,
      'quantity': instance.quantity,
      'barcode': instance.barcode,
      'taxable': instance.taxable,
      'bottleDeposit': instance.bottleDeposit,
      'receiptUid': instance.receiptUid,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
