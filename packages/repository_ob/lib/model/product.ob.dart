// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/product.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxProduct extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
  late String name;
  late String uid;
  late String manufacturer;
  late String manufacturerUid;
  late String category;
  List<String> upcs = [];
  ObjectBoxProduct();
  ObjectBoxProduct.from(Product original) {
    created = original.created;
    updated = original.updated;
    name = original.name;
    uid = original.uid;
    manufacturer = original.manufacturer;
    manufacturerUid = original.manufacturerUid;
    category = original.category;
    upcs = original.upcs;
  }
  Product toProduct() {
    return Product(
        created: created,
        updated: updated,
        name: name,
        uid: uid,
        manufacturer: manufacturer,
        manufacturerUid: manufacturerUid,
        category: category,
        upcs: upcs);
  }
}
