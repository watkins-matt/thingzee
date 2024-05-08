// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/product.dart';

part 'product.hive.g.dart';

@HiveType(typeId: 0)
class HiveProduct extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late String uid;
  @HiveField(4)
  late String manufacturer;
  @HiveField(5)
  late String manufacturerUid;
  @HiveField(6)
  late String category;
  @HiveField(7)
  late List<String> upcs;
  HiveProduct();
  HiveProduct.from(Product original) {
    created = original.created;
    updated = original.updated;
    name = original.name;
    uid = original.uid;
    manufacturer = original.manufacturer;
    manufacturerUid = original.manufacturerUid;
    category = original.category;
    upcs = original.upcs;
  }
  Product convert() {
    return Product(
        category: category,
        created: created,
        manufacturer: manufacturer,
        manufacturerUid: manufacturerUid,
        name: name,
        uid: uid,
        upcs: upcs,
        updated: updated);
  }
}
