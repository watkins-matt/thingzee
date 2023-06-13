import 'package:quiver/core.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:repository/model/inventory.dart';

abstract class HistoryDatabase {
  List<MLHistory> all();
  void deleteAll();
  Optional<MLHistory> get(String upc);
  Map<String, Inventory> join(Map<String, Inventory> inventoryMap);
  List<Inventory> joinList(List<Inventory> inventoryList);
  Map<String, MLHistory> map();
  List<MLHistory> predictedOuts(int days);
  void put(MLHistory history);
}
