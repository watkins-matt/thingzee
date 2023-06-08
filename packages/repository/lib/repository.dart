import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';

abstract class Repository {
  bool ready = false;

  late ItemDatabase items;
  late InventoryDatabase inv;
  late HistoryDatabase hist;
}
