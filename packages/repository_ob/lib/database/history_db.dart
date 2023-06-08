import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:repository_ob/model_custom/ml_history_ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxHistoryDatabase extends HistoryDatabase {
  late Box<ObjectBoxMLHistory> box;

  ObjectBoxHistoryDatabase(Store store) {
    box = store.box<ObjectBoxMLHistory>();
  }

  @override
  List<MLHistory> all() {
    final all = box.getAll();
    return all.map((objBoxHist) => objBoxHist.toMLHistory()).toList();
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  MLHistory get(String upc) {
    final query = box.query(ObjectBoxMLHistory_.upc.equals(upc)).build();
    final result = Optional.fromNullable(query.findFirst()?.toMLHistory());
    query.close();

    return result.isPresent ? result.value : MLHistory()
      ..upc = upc;
  }

  @override
  Map<String, MLHistory> map() {
    Map<String, MLHistory> map = {};
    final allHistory = all();

    for (final hist in allHistory) {
      map[hist.upc] = hist;
    }

    return map;
  }

  @override
  void put(MLHistory history) {
    assert(history.upc.isNotEmpty);
    final historyOb = ObjectBoxMLHistory.from(history);

    final query = box.query(ObjectBoxMLHistory_.upc.equals(history.upc)).build();
    final exists = Optional.fromNullable(query.findFirst());
    query.close();

    if (exists.isPresent && historyOb.id != exists.value.id) {
      historyOb.id = exists.value.id;
    }

    assert(historyOb.upc.isNotEmpty && historyOb.history.upc.isNotEmpty);
    box.put(historyOb);
  }
}
