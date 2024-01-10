import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/list.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:uuid/uuid.dart';

part 'receipt.g.dart';

@JsonSerializable()
@immutable
class Receipt extends Model<Receipt> {
  @JsonKey(defaultValue: [])
  final List<ReceiptItem> items;

  @JsonKey(defaultValue: null)
  final DateTime? date;

  @JsonKey(defaultValue: 0.0)
  final double subtotal;

  @JsonKey(defaultValue: [])
  final List<double> discounts;

  @JsonKey(defaultValue: 0.0)
  final double tax;

  @JsonKey(defaultValue: 0.0)
  final double total;

  @JsonKey(defaultValue: '')
  final String uid;

  Receipt({
    required this.items,
    required this.date,
    this.subtotal = 0.0,
    this.discounts = const [],
    this.tax = 0.0,
    this.total = 0.0,
    String? uid,
    super.created,
    super.updated,
  }) : uid = uid ?? const Uuid().v4();

  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

  double get calculatedSubtotal {
    return items.fold(0, (previousValue, element) => previousValue + element.totalPrice);
  }

  @override
  String get id => uid;

  Receipt copyAndReplaceItem(int index, ReceiptItem newItem) {
    var newItems = List<ReceiptItem>.from(items);
    if (index >= 0 && index < items.length) {
      newItems[index] = newItem;
    }
    return copyWith(items: newItems);
  }

  Receipt copyWith({
    List<ReceiptItem>? items,
    DateTime? date,
    double? subtotal,
    List<double>? discounts,
    double? tax,
    double? total,
  }) {
    return Receipt(
      items: items ?? this.items,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discounts: discounts ?? this.discounts,
      tax: tax ?? this.tax,
      total: total ?? this.total,
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
        items.equals(other.items);
  }

  @override
  Receipt merge(Receipt other) {
    final newer = (updated != null &&
            updated!.isAfter(other.updated ?? DateTime.fromMillisecondsSinceEpoch(0)))
        ? this
        : other;

    return Receipt(
      items: newer.items.isNotEmpty ? newer.items : items,
      date: date != null && newer.date!.isAfter(date!) ? newer.date : date,
      subtotal: newer.subtotal != 0.0 ? newer.subtotal : subtotal,
      discounts: newer.discounts.isNotEmpty ? newer.discounts : discounts,
      tax: newer.tax != 0.0 ? newer.tax : tax,
      total: newer.total != 0.0 ? newer.total : total,
      uid: newer.uid.isNotEmpty ? newer.uid : uid,
      created: _determineOlderCreatedDate(created, other.created),
      updated: !equalTo(newer) ? DateTime.now() : newer.updated,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ReceiptToJson(this);

  static DateTime _determineOlderCreatedDate(DateTime? date1, DateTime? date2) {
    return date1 ?? date2 ?? DateTime.now();
  }
}
