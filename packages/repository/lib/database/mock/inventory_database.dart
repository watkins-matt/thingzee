import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/mock/mock_database.dart';
import 'package:repository/model/inventory.dart';

class MockInventoryDatabase extends InventoryDatabase with MockDatabase<Inventory> {
  @override
  List<Inventory> outs() => all().where((inv) => inv.amount == 0).toList();
}
