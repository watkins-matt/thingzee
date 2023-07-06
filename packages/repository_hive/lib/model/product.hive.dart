import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/product.dart';

part 'product.hive.g.dart';
@HiveType(typeId: 4)
class HiveProduct extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late String puid;
  @HiveField(2)
  late String manufacturer;
  @HiveField(3)
  late String muid;
  @HiveField(4)
  late String category;
  @HiveField(5)
  late List<String> upcs;
  HiveProduct();
  HiveProduct.from(Product original) {
    name = original.name;
    puid = original.puid;
    manufacturer = original.manufacturer;
    muid = original.muid;
    category = original.category;
    upcs = original.upcs;
  }
  Product toProduct() {
    return Product()
      ..name = name
      ..puid = puid
      ..manufacturer = manufacturer
      ..muid = muid
      ..category = category
      ..upcs = upcs
    ;
  }
}
