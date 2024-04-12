import 'package:repository/database/history_database.dart';
import 'package:repository/database/mock/mock_database.dart';
import 'package:repository/ml/history.dart';

class MockHistoryDatabase extends HistoryDatabase with MockDatabase<History> {}
