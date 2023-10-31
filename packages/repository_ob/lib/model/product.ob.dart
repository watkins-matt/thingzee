import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/product.dart';

@Entity()
class ObjectBoxProduct {
  late String name;
  late String uid;
  late String manufacturer;
  late String manufacturerUid;
  late String category;
  List<String> upcs = [];
  @Id()
  int objectBoxId = 0;
  ObjectBoxProduct();
  ObjectBoxProduct.from(Product original) {
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
