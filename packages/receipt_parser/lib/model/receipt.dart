import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:util/extension/list.dart';
import 'package:uuid/uuid.dart';

@immutable
class ParsedReceipt {
  @JsonKey(defaultValue: [])
  final List<ParsedReceiptItem> items; // generator:transient

  @JsonKey(defaultValue: null)
  final DateTime? date;

  final double subtotal;
  final List<double> discounts;
  final double tax;
  final double total;

  @JsonKey(defaultValue: '')
  final String uid;

  final String barcodeType;

  ParsedReceipt({
    required this.items,
    required this.date,
    this.subtotal = 0.0,
    this.discounts = const [],
    this.tax = 0.0,
    this.total = 0.0,
    this.barcodeType = 'UPC',
    String? uid,
  }) : uid = uid ?? const Uuid().v4();

  double get calculatedSubtotal {
    return items.fold(0, (previousValue, element) => previousValue + element.totalPrice);
  }

  ParsedReceipt copyAndReplaceItem(int index, ParsedReceiptItem newItem) {
    var newItems = List<ParsedReceiptItem>.from(items);
    if (index >= 0 && index < items.length) {
      newItems[index] = newItem;
    }
    return copyWith(items: newItems);
  }

  ParsedReceipt copyWith({
    List<ParsedReceiptItem>? items,
    DateTime? date,
    double? subtotal,
    List<double>? discounts,
    double? tax,
    double? total,
    String? barcodeType,
    DateTime? created,
    DateTime? updated,
  }) {
    return ParsedReceipt(
      items: items ?? this.items,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discounts: discounts ?? this.discounts,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      barcodeType: barcodeType ?? this.barcodeType,
    );
  }

  bool equalTo(ParsedReceipt other) {
    return uid == other.uid &&
        date == other.date &&
        subtotal == other.subtotal &&
        discounts.equals(other.discounts) &&
        tax == other.tax &&
        total == other.total &&
        barcodeType == other.barcodeType &&
        items.equals(other.items);
  }
}
