import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase {
  List<Inventory> all();
  void delete(Inventory inv);
  void deleteAll();
  Inventory? get(String upc);
  List<Inventory> getAll(List<String> upcs);
  List<Inventory> getChanges(DateTime since);
  Map<String, Inventory> map();
  List<Inventory> outs();
  void put(Inventory inv);
}
