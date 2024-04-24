import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';
import 'package:util/extension/list.dart';
import 'package:uuid/uuid.dart';

part 'receipt.g.dart';
part 'receipt.merge.dart';

@JsonSerializable()
@immutable
@Mergeable()
class Receipt extends Model<Receipt> {
  @JsonKey(defaultValue: [])
  final List<ReceiptItem> items; // generator:transient

  @JsonKey(defaultValue: null)
  final DateTime? date;

  final double subtotal;
  final List<double> discounts;
  final double tax;
  final double total;

  @JsonKey(defaultValue: '')
  final String uid;

  final String barcodeType;

  Receipt({
    required this.items,
    required this.date,
    this.subtotal = 0.0,
    this.discounts = const [],
    this.tax = 0.0,
    this.total = 0.0,
    this.barcodeType = IdentifierType.upc,
    String? uid,
    super.created,
    super.updated,
  }) : uid = uid ?? const Uuid().v4();

  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

  double get calculatedSubtotal {
    return items.fold(0, (previousValue, element) => previousValue + element.totalPrice);
  }

  @override
  String get uniqueKey => uid;

  Receipt copyAndReplaceItem(int index, ReceiptItem newItem) {
    var newItems = List<ReceiptItem>.from(items);
    if (index >= 0 && index < items.length) {
      newItems[index] = newItem;
    }
    return copyWith(items: newItems);
  }

  @override
  Receipt copyWith({
    List<ReceiptItem>? items,
    DateTime? date,
    double? subtotal,
    List<double>? discounts,
    double? tax,
    double? total,
    String? barcodeType,
    DateTime? created,
    DateTime? updated,
  }) {
    return Receipt(
      items: items ?? this.items,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discounts: discounts ?? this.discounts,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      barcodeType: barcodeType ?? this.barcodeType,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Receipt other) {
    return uid == other.uid &&
        date == other.date &&
        subtotal == other.subtotal &&
        discounts.equals(other.discounts) &&
        tax == other.tax &&
        total == other.total &&
        barcodeType == other.barcodeType &&
        items.equals(other.items);
  }

  @override
  Receipt merge(Receipt other) => _$mergeReceipt(this, other);

  @override
  Map<String, dynamic> toJson() => _$ReceiptToJson(this);
}
