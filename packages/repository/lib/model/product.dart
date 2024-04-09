import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';
import 'package:util/extension/list.dart';

part 'product.g.dart';
part 'product.merge.dart';

@JsonSerializable()
@immutable
@Mergeable()
class Product extends Model<Product> implements Comparable<Product> {
  final String name;
  final String uid;
  final String manufacturer;
  final String manufacturerUid;
  final String category;
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

  @override
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
  Product merge(Product other) => _$mergeProduct(this, other);

  @override
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
