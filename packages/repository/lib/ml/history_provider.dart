import 'package:repository/ml/history.dart';
import 'package:repository/repository.dart';

class HistoryProvider {
  static final HistoryProvider _instance = HistoryProvider._internal();
  final Map<String, History> _history = {};
  Repository? _repo;

  factory HistoryProvider() {
    return _instance;
  }

  HistoryProvider._internal();

  Repository get repo {
    final r = _repo;

    if (r == null) {
      throw Exception('HistoryProvider not initialized with a Repository instance.');
    }

    return r;
  }

  History getHistory(String upc) {
    var history = _history[upc];

    if (history == null) {
      history = repo.hist.get(upc) ?? History(upc: upc);
      _history[upc] = history;
    }

    return history;
  }

  void init(Repository repository) {
    _instance._repo = repository;
  }

  void updateHistory(History newHistory, [bool force = false]) {
    final upc = newHistory.upc;
    final currentHistory = _history[upc];

    if (!force &&
            (currentHistory != null) &&
            (newHistory.series.length < currentHistory.series.length) ||
        (newHistory.totalPoints < currentHistory!.totalPoints)) {
      throw Exception('Cannot replace history with a version containing less data.');
    }

    _history[upc] = newHistory;
  }
}
