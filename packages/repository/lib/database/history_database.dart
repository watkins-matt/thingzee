import 'package:repository/database/database.dart';
import 'package:repository/ml/history.dart';

abstract class HistoryDatabase extends Database<History> {
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
}
