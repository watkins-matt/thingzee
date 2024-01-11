import 'package:repository/database/database.dart';
import 'package:repository/mixin/fuzzy_searchable.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

abstract class ItemDatabase with FuzzySearchable<Item> implements Database<Item> {
  List<Item> filter(Filter filter);
  List<Item> search(String string);
}
