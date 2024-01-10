import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/list.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'product.g.dart';

@JsonSerializable()
@immutable
class Product extends Model<Product> implements Comparable<Product> {
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String uid;

  @JsonKey(defaultValue: '')
  final String manufacturer;

  @JsonKey(defaultValue: '')
  final String manufacturerUid;

  @JsonKey(defaultValue: '')
  final String category;

  @JsonKey(defaultValue: [])
  final List<String> upcs;

  Product({
    this.name = '',
    this.uid = '',
    this.manufacturer = '',
    this.manufacturerUid = '',
    this.category = '',
    this.upcs = const <String>[],
    super.created,
    super.updated,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  @override
  String get id => uid;

  @override
  int compareTo(Product other) {
    return name.compareTo(other.name);
  }

  Product copyWith({
    String? name,
    String? uid,
    String? manufacturer,
    String? manufacturerUid,
    String? category,
    List<String>? upcs,
    DateTime? created,
    DateTime? updated,
  }) {
    return Product(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      manufacturer: manufacturer ?? this.manufacturer,
      manufacturerUid: manufacturerUid ?? this.manufacturerUid,
      category: category ?? this.category,
      upcs: upcs ?? this.upcs,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Product other) {
    return uid == other.uid &&
        name == other.name &&
        manufacturer == other.manufacturer &&
        manufacturerUid == other.manufacturerUid &&
        category == other.category &&
        upcs.equals(other.upcs);
  }

  @override
  Product merge(Product other) {
    final newer = (updated != null &&
            updated!.isAfter(other.updated ?? DateTime.fromMillisecondsSinceEpoch(0)))
        ? this
        : other;

    final mergedProduct = Product(
      name: newer.name.isNotEmpty ? newer.name : name,
      uid: newer.uid.isNotEmpty ? newer.uid : uid,
      manufacturer: newer.manufacturer.isNotEmpty ? newer.manufacturer : manufacturer,
      manufacturerUid: newer.manufacturerUid.isNotEmpty ? newer.manufacturerUid : manufacturerUid,
      category: newer.category.isNotEmpty ? newer.category : category,
      upcs: newer.upcs.isNotEmpty ? newer.upcs : upcs,
      created: _determineOlderCreatedDate(created, other.created),
      updated: DateTime.now(), // Set to now initially
    );

    DateTime? finalUpdatedDate = mergedProduct.equalTo(newer) ? newer.updated : DateTime.now();

    return Product(
      name: mergedProduct.name,
      uid: mergedProduct.uid,
      manufacturer: mergedProduct.manufacturer,
      manufacturerUid: mergedProduct.manufacturerUid,
      category: mergedProduct.category,
      upcs: mergedProduct.upcs,
      created: mergedProduct.created,
      updated: finalUpdatedDate ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  static DateTime _determineOlderCreatedDate(DateTime? date1, DateTime? date2) {
    return date1 ?? date2 ?? DateTime.now();
  }
}
