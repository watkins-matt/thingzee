import 'package:repository/database/database.dart';
import 'package:repository/model/inventory.dart';

abstract class InventoryDatabase implements Database<Inventory> {
  List<Inventory> outs();
}
