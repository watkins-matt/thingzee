import 'package:repository/database/database.dart';
import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase extends Database<Inventory> {
  List<Inventory> outs();
}
