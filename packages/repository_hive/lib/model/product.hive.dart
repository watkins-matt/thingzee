import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/product.dart';

part 'product.hive.g.dart';

@HiveType(typeId: 4)
class HiveProduct extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late String uid;
  @HiveField(2)
  late String manufacturer;
  @HiveField(3)
  late String manufacturerUid;
  @HiveField(4)
  late String category;
  @HiveField(5)
  late List<String> upcs;
  HiveProduct();
  HiveProduct.from(Product original) {
    name = original.name;
    uid = original.uid;
    manufacturer = original.manufacturer;
    manufacturerUid = original.manufacturerUid;
    category = original.category;
    upcs = original.upcs;
  }
  Product toProduct() {
    return Product()
      ..name = name
      ..uid = uid
      ..manufacturer = manufacturer
      ..manufacturerUid = manufacturerUid
      ..category = category
      ..upcs = upcs;
  }
}
