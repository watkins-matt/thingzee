import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/inventory.dart';

class SynchronizedInventoryDatabase extends InventoryDatabase
    with SynchronizedDatabase<Inventory, InventoryDatabase> {
  static const String tag = 'SynchronizedInventoryDatabase';

  SynchronizedInventoryDatabase(
      InventoryDatabase local, InventoryDatabase remote, Preferences prefs)
      : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }

  @override
  List<Inventory> outs() => local.outs();
}
