import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';

class MockHistoryDatabase extends HistoryDatabase {
  final Map<String, History> _db = {};

  @override
  List<History> all() => _db.values.toList();

  @override
  void delete(History history) => _db.remove(history.upc);

  @override
  void deleteAll() => _db.clear();

  @override
  void deleteById(String id) {
    _db.remove(id);
  }

  @override
  History? get(String upc) => _db[upc];

  @override
  List<History> getAll(List<String> ids) {
    final all = _db.values.toList();
    final unmodifiableList = List<History>.unmodifiable(all);
    return unmodifiableList;
  }

  @override
  Map<String, History> map() => Map.from(_db);

  @override
  void put(History history) => _db[history.upc] = history;
}
