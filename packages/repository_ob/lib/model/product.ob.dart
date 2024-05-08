// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/product.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxProduct extends ObjectBoxModel<Product> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  List<String> upcs = [];
  late String category;
  late String manufacturer;
  late String manufacturerUid;
  late String name;
  late String uid;
  ObjectBoxProduct();
  ObjectBoxProduct.from(Product original) {
    category = original.category;
    created = original.created;
    manufacturer = original.manufacturer;
    manufacturerUid = original.manufacturerUid;
    name = original.name;
    uid = original.uid;
    upcs = original.upcs;
    updated = original.updated;
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
