import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';

abstract class Repository {
  bool ready = false;
  bool get isMultiUser => false;

  late ItemDatabase items;
  late InventoryDatabase inv;
  late HistoryDatabase hist;
}

abstract class SharedRepository extends Repository {
  @override
  bool get isMultiUser => true;

  Future<void> registerUser(String username, String email, String password);
  Future<void> loginUser(String username, String password);
}
