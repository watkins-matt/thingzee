import 'package:repository/ml/ml_history.dart';

abstract class HistoryDatabase {
  List<MLHistory> all();
  Map<String, MLHistory> map();
  MLHistory get(String upc);
  void deleteAll();
  void put(MLHistory history);
}
