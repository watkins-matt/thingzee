import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';

class MockInventoryDatabase extends InventoryDatabase {
  final Map<String, Inventory> _db = {};

  @override
  List<Inventory> all() => _db.values.toList();

  @override
  void delete(Inventory inv) => _db.remove(inv.upc);

  @override
  void deleteAll() => _db.clear();

  @override
  void deleteById(String upc) => _db.remove(upc);

  @override
  Inventory? get(String upc) => _db[upc];

  @override
  List<Inventory> getAll(List<String> upcs) =>
      upcs.map((upc) => _db[upc]).whereType<Inventory>().toList();

  @override
  List<Inventory> getChanges(DateTime since) =>
      all().where((inv) => inv.lastUpdate != null && inv.lastUpdate!.isAfter(since)).toList();

  @override
  Map<String, Inventory> map() => Map.from(_db);

  @override
  List<Inventory> outs() => all().where((inv) => inv.amount == 0).toList();

  @override
  void put(Inventory inv) => _db[inv.upc] = inv;
}
