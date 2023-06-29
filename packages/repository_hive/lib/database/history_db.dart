import 'package:hive/hive.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository_hive/model_custom/history.hive.dart';

class HiveHistoryDatabase extends HistoryDatabase {
  late Box<HiveHistory> box;

  HiveHistoryDatabase() {
    box = Hive.box<HiveHistory>('history');
  }

  @override
  List<History> all() {
    final all = box.values.toList();
    return all.map((hiveHistory) => hiveHistory.toHistory()).toList();
  }

  @override
  void delete(History history) {
    box.delete(history.upc);
  }

  @override
  void deleteAll() {
    box.clear();
  }

  @override
  Optional<History> get(String upc) {
    final existingHistory = box.get(upc);
    return Optional.fromNullable(existingHistory?.toHistory());
  }

  @override
  Map<String, History> map() {
    final historyMap = <String, History>{};
    final allHistory = all();

    for (final hist in allHistory) {
      historyMap[hist.upc] = hist;
    }

    return historyMap;
  }

  @override
  void put(History history) {
    assert(history.upc.isNotEmpty);
    history = history.clean();
    final hiveHistory = HiveHistory.from(history);
    box.put(history.upc, hiveHistory);
  }
}
