import 'package:repository/mixin/fuzzy_searchable.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

abstract class ItemDatabase with FuzzySearchable<Item> {
  @override
  List<Item> all();
  void delete(Item item);
  void deleteAll();
  List<Item> filter(Filter filter);
  Item? get(String upc);
  List<Item> getAll(List<String> upcs);
  List<Item> getChanges(DateTime since);
  Map<String, Item> map();
  void put(Item item);
  List<Item> search(String string);
}
