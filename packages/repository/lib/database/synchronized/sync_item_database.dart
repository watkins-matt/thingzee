import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class SynchronizedItemDatabase extends ItemDatabase {
  final ItemDatabase local;
  final ItemDatabase remote;
  DateTime? lastSync;

  SynchronizedItemDatabase(this.local, this.remote) {
    synchronize();
  }

  @override
  List<Item> all() {
    return local.all();
  }

  @override
  void delete(Item item) {
    local.delete(item);
    remote.delete(item);
  }

  @override
  void deleteAll() {
    local.deleteAll();
    remote.deleteAll();
  }

  @override
  List<Item> filter(Filter filter) {
    return local.filter(filter);
  }

  @override
  Item? get(String upc) {
    return local.get(upc);
  }

  @override
  List<Item> getAll(List<String> upcs) {
    return local.getAll(upcs);
  }

  @override
  List<Item> getChanges(DateTime since) {
    return local.getChanges(since);
  }

  @override
  Map<String, Item> map() {
    return local.map();
  }

  @override
  void put(Item item) {
    local.put(item);
    remote.put(item);
  }

  @override
  List<Item> search(String string) {
    return local.search(string);
  }

  void syncDifferences() {
    final since = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);

    final remoteChanges = remote.getChanges(since);
    final localChanges = local.getChanges(since);

    final remoteMap = {for (var item in remoteChanges) item.upc: item};
    final localMap = {for (var item in localChanges) item.upc: item};

    for (final remoteItem in remoteChanges) {
      if (!localMap.containsKey(remoteItem.upc)) {
        // If the local database does not contain the remote item, add it
        local.put(remoteItem);
      }
      // The item exists in both databases, merge and add to both
      else {
        final mergedItem = localMap[remoteItem.upc]!.merge(remoteItem);
        local.put(mergedItem);
        remote.put(mergedItem);
      }
    }

    for (final localItem in localChanges) {
      if (!remoteMap.containsKey(localItem.upc)) {
        // If the remote database does not contain the local item, add it
        remote.put(localItem);
      }
    }
  }

  void synchronize() {
    // Fetch all items from both databases
    var localItems = local.map();
    var remoteItems = remote.map();

    // First go through all the remote items, add the missing ones
    // to the database and merge the ones that exist in both
    for (final remoteItem in remoteItems.values) {
      if (!localItems.containsKey(remoteItem.upc)) {
        // If the local database does not contain the remote item, add it
        local.put(remoteItem);
      }
      // The item exists in both databases
      else {
        final mergedItem = localItems[remoteItem.upc]!.merge(remoteItem);
        local.put(mergedItem);
        remote.put(mergedItem);
      }
    }

    // Now look for local items that are missing in the remote, and
    // add them to the remote database
    for (final localItem in localItems.values) {
      if (!remoteItems.containsKey(localItem.upc)) {
        // If the remote database does not contain the local item, add it
        remote.put(localItem);
      }
    }

    lastSync = DateTime.now();
  }
}
