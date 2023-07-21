import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';
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
    return all.map((objBoxHist) => objBoxHist.toHistory()).toList();
  }

  @override
  void delete(History history) {
    assert(history.upc.isNotEmpty);
    final query = box.query(ObjectBoxHistory_.upc.equals(history.upc)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  History? get(String upc) {
    assert(upc.isNotEmpty);
    final query = box.query(ObjectBoxHistory_.upc.equals(upc)).build();
    final result = query.findFirst()?.toHistory();
    query.close();

    return result;
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
  void put(History history) {
    // Ensure UPC is not empty
    assert(history.upc.isNotEmpty);

    // Remove any invalid values
    history = history.clean();

    // Convert to ObjectBoxMLHistory
    final historyOb = ObjectBoxHistory.from(history);

    // Check if history already exists
    final query = box.query(ObjectBoxHistory_.upc.equals(history.upc)).build();
    final exists = query.findFirst();
    query.close();

    // If history exists, update the ID to match the existing history
    // before we replace it
    if (exists != null && historyOb.objectBoxId != exists.objectBoxId) {
      historyOb.objectBoxId = exists.objectBoxId;
    }

    assert(historyOb.upc.isNotEmpty && historyOb.history.upc.isNotEmpty);
    box.put(historyOb);
  }
}
