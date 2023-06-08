import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/product.dart';
@Entity()
class ObjectBoxProduct {
  late String name;
  late String puid;
  late String manufacturer;
  late String muid;
  late String category;
  List<String> upcs = [];
  @Id()
  int id = 0;
  ObjectBoxProduct();
  ObjectBoxProduct.from(Product original) {
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
