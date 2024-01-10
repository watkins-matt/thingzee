import 'package:repository/database/history_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/ml/history.dart';

class SynchronizedHistoryDatabase extends HistoryDatabase with SynchronizedDatabase<History> {
  static const String tag = 'SynchronizedHistoryDatabase';

  SynchronizedHistoryDatabase(HistoryDatabase local, HistoryDatabase remote, Preferences prefs)
      : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }
}
