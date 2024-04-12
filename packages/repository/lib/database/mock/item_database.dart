import 'package:repository/database/item_database.dart';
import 'package:repository/database/mock/mock_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class MockItemDatabase extends ItemDatabase with MockDatabase<Item> {
  @override
  List<Item> filter(Filter filter) => db.values
      .where((item) =>
          (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
      .toList();

  @override
  List<Item> search(String string) => all().where((item) => item.name.contains(string)).toList();
}
