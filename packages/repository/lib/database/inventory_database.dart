import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase {
  List<Inventory> all();
  void delete(Inventory inv);
  void deleteAll();
  Optional<Inventory> get(String upc);
  Map<String, Inventory> map();
  void put(Inventory inv);
}
