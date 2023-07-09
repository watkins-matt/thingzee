import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class MockItemDatabase extends ItemDatabase {
  final Map<String, Item> _db = {};

  @override
  List<Item> all() => _db.values.toList();

  @override
  void delete(Item item) => _db.remove(item.upc);

  @override
  void deleteAll() => _db.clear();

  @override
  List<Item> filter(Filter filter) => _db.values
      .where((item) =>
          (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
      .toList();

  @override
  Item? get(String upc) => _db[upc];

  @override
  List<Item> getAll(List<String> upcs) => upcs.map((upc) => _db[upc]).whereType<Item>().toList();

  @override
  List<Item> getChanges(DateTime since) =>
      all().where((item) => item.lastUpdate != null && item.lastUpdate!.isAfter(since)).toList();

  @override
  Map<String, Item> map() => Map.from(_db);

  @override
  void put(Item item) => _db[item.upc] = item;

  @override
  List<Item> search(String string) => all().where((item) => item.name.contains(string)).toList();
}
