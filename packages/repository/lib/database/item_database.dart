import 'package:repository/database/database.dart';
import 'package:repository/mixin/fuzzy_searchable.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

abstract class ItemDatabase extends Database<Item> with FuzzySearchable<Item> {
  List<Item> filter(Filter filter);
  List<Item> search(String string);
}
