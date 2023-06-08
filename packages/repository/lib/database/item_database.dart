import 'package:quiver/core.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

abstract class ItemDatabase {
  Optional<Item> get(String upc);
  void put(Item item);
  void delete(Item item);
  void deleteAll();
  List<Item> all();
  List<Item> filter(Filter filter);
  List<Item> search(String string);
}
