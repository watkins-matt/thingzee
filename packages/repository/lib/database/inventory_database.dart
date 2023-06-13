import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase {
  List<Inventory> all();
  void delete(Inventory inv);
  void deleteAll();
  Optional<Inventory> get(String upc);
  List<Inventory> getAll(List<String> upcs);
  Map<String, Inventory> map();
  List<Inventory> outs();
  void put(Inventory inv);
}
