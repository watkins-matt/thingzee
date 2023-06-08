import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase {
  Map<String, Inventory> map();
  List<Inventory> all();
  void delete(Inventory inv);
  void deleteAll();
  Optional<Inventory> get(String upc);
  void put(Inventory inv);
}
