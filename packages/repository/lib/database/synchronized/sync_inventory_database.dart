import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';

class SynchronizedInventoryDatabase extends InventoryDatabase {
  final InventoryDatabase local;
  final InventoryDatabase remote;
  DateTime? lastSync;

  SynchronizedInventoryDatabase(this.local, this.remote) {
    synchronize();
  }

  @override
  List<Inventory> all() {
    return local.all();
  }

  @override
  void delete(Inventory inv) {
    local.delete(inv);
    remote.delete(inv);
  }

  @override
  void deleteAll() {
    local.deleteAll();
    remote.deleteAll();
  }

  @override
  Inventory? get(String upc) {
    return local.get(upc);
  }

  @override
  List<Inventory> getAll(List<String> upcs) {
    return local.getAll(upcs);
  }

  @override
  List<Inventory> getChanges(DateTime since) {
    return local.getChanges(since);
  }

  @override
  Map<String, Inventory> map() {
    return local.map();
  }

  @override
  List<Inventory> outs() {
    return local.outs();
  }

  @override
  void put(Inventory inv) {
    local.put(inv);
    remote.put(inv);
  }

  void syncDifferences() {
    final since = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);

    final remoteChanges = remote.getChanges(since);
    final localChanges = local.getChanges(since);

    final remoteMap = {for (var inventory in remoteChanges) inventory.upc: inventory};
    final localMap = {for (var inventory in localChanges) inventory.upc: inventory};

    for (final remoteInventory in remoteChanges) {
      if (!localMap.containsKey(remoteInventory.upc)) {
        // If the local database does not contain the remote inventory, add it
        local.put(remoteInventory);
      }
      // The inventory exists in both databases, merge and add to both
      else {
        final mergedInventory = localMap[remoteInventory.upc]!.merge(remoteInventory);
        local.put(mergedInventory);
        remote.put(mergedInventory);
      }
    }

    for (final localInventory in localChanges) {
      if (!remoteMap.containsKey(localInventory.upc)) {
        // If the remote database does not contain the local inventory, add it
        remote.put(localInventory);
      }
    }
  }

  void synchronize() {
    // Fetch all inventories from both databases
    var localInventories = local.map();
    var remoteInventories = remote.map();

    // First go through all the remote inventories, add the missing ones
    // to the database and merge the ones that exist in both
    for (final remoteInventory in remoteInventories.values) {
      if (!localInventories.containsKey(remoteInventory.upc)) {
        // If the local database does not contain the remote inventory, add it
        local.put(remoteInventory);
      }
      // The inventory exists in both databases
      else {
        final mergedInventory = localInventories[remoteInventory.upc]!.merge(remoteInventory);
        local.put(mergedInventory);
        remote.put(mergedInventory);
      }
    }

    // Now look for local inventories that are missing in the remote, and
    // add them to the remote database
    for (final localInventory in localInventories.values) {
      if (!remoteInventories.containsKey(localInventory.upc)) {
        // If the remote database does not contain the local inventory, add it
        remote.put(localInventory);
      }
    }

    lastSync = DateTime.now();
  }
}
