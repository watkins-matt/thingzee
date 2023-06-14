import 'package:quiver/core.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

abstract class ItemDatabase {
  List<Item> all();
  void delete(Item item);
  void deleteAll();
  List<Item> filter(Filter filter);
  List<Item> getAll(List<String> upcs);
  Optional<Item> get(String upc);
  void put(Item item);
  List<Item> search(String string);
}
