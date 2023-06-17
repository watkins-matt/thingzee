import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/model_custom/history_ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxHistoryDatabase extends HistoryDatabase {
  late Box<ObjectBoxHistory> box;

  ObjectBoxHistoryDatabase(Store store) {
    box = store.box<ObjectBoxHistory>();
  }

  @override
  List<History> all() {
    final all = box.getAll();
    return all.map((objBoxHist) => objBoxHist.toMLHistory()).toList();
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  Optional<History> get(String upc) {
    assert(upc.isNotEmpty);
    final query = box.query(ObjectBoxHistory_.upc.equals(upc)).build();
    final result = Optional.fromNullable(query.findFirst()?.toMLHistory());
    query.close();

    return result;
  }

  @override
  Map<String, Inventory> join(Map<String, Inventory> inventoryMap) {
    final allHistory = map();

    for (final inventory in inventoryMap.values) {
      if (inventory.upc.isNotEmpty && allHistory.containsKey(inventory.upc)) {
        final history = allHistory[inventory.upc]!;
        assert(history.upc.isNotEmpty && history.upc == inventory.upc);
        inventory.history = history;
      }
    }
    return inventoryMap;
  }

  @override
  List<Inventory> joinList(List<Inventory> inventoryList) {
    final allHistory = map();

    for (final inventory in inventoryList) {
      if (inventory.upc.isNotEmpty && allHistory.containsKey(inventory.upc)) {
        final history = allHistory[inventory.upc]!;
        assert(history.upc.isNotEmpty && history.upc == inventory.upc);
        inventory.history = history;
      }
    }

    return inventoryList;
  }

  @override
  Map<String, History> map() {
    Map<String, History> map = {};
    final allHistory = all();

    for (final hist in allHistory) {
      map[hist.upc] = hist;
    }

    return map;
  }

  @override
  Set<String> predictedOuts(int days) {
    final allHistory = all();
    Set<String> predictedOuts = {};
    final futureDate = DateTime.now().add(const Duration(days: 12));

    for (final history in allHistory) {
      if (history.canPredict) {
        final outTime = DateTime.fromMillisecondsSinceEpoch(history.predictedOutageTimestamp);
        if (outTime.isBefore(futureDate)) {
          predictedOuts.add(history.upc);
        }
      }
    }

    return predictedOuts;
  }

  @override
  void put(History history) {
    // Ensure UPC is not empty
    assert(history.upc.isNotEmpty);

    // Remove any invalid values
    history = history.clean();

    // Convert to ObjectBoxMLHistory
    final historyOb = ObjectBoxHistory.from(history);

    // Check if history already exists
    final query = box.query(ObjectBoxHistory_.upc.equals(history.upc)).build();
    final exists = Optional.fromNullable(query.findFirst());
    query.close();

    // If history exists, update the ID to match the existing history
    // before we replace it
    if (exists.isPresent && historyOb.id != exists.value.id) {
      historyOb.id = exists.value.id;
    }

    assert(historyOb.upc.isNotEmpty && historyOb.history.upc.isNotEmpty);
    box.put(historyOb);
  }
}
