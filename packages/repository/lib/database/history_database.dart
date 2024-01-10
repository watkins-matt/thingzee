import 'package:repository/database/database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';

abstract class HistoryDatabase implements Database<History> {
  @override
  List<History> getChanges(DateTime since) {
    final allHistory = all();
    List<History> changes = [];

    for (final history in allHistory) {
      final lastTimestamp = history.lastTimestamp;

      if (lastTimestamp != null && lastTimestamp.isAfter(since)) {
        changes.add(history);
      }
    }

    return changes;
  }

  Map<String, Inventory> join(Map<String, Inventory> inventoryMap) {
    final allHistory = map();

    for (var inventory in inventoryMap.values) {
      if (inventory.upc.isNotEmpty && allHistory.containsKey(inventory.upc)) {
        final history = allHistory[inventory.upc]!;
        assert(history.upc.isNotEmpty && history.upc == inventory.upc);
        inventory = inventory.copyWith(history: history);
      }
    }
    return inventoryMap;
  }

  List<Inventory> joinList(List<Inventory> inventoryList) {
    final allHistory = map();

    for (var inventory in inventoryList) {
      if (inventory.upc.isNotEmpty && allHistory.containsKey(inventory.upc)) {
        final history = allHistory[inventory.upc]!;
        assert(history.upc.isNotEmpty && history.upc == inventory.upc);
        inventory = inventory.copyWith(history: history);
      }
    }

    return inventoryList;
  }

  @override
  Map<String, History> map();

  Set<String> predictedOuts({int days = 12}) {
    final allHistory = all();
    Set<String> predictedOuts = {};
    final futureDate = DateTime.now().add(Duration(days: days));

    for (final history in allHistory) {
      if (history.canPredict) {
        final outTime =
            DateTime.fromMillisecondsSinceEpoch(history.predictedOutageTimestamp.round());
        if (outTime.isBefore(futureDate)) {
          predictedOuts.add(history.upc);
        }
      }
    }

    return predictedOuts;
  }

  @override
  void put(History history);
}
