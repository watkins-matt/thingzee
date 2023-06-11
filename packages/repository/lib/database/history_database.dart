import 'package:quiver/core.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:repository/model/inventory.dart';

abstract class HistoryDatabase {
  List<MLHistory> all();
  Map<String, MLHistory> map();
  Optional<MLHistory> get(String upc);
  void deleteAll();
  void put(MLHistory history);

  Map<String, Inventory> join(Map<String, Inventory> inventoryMap);
  List<Inventory> joinList(List<Inventory> inventoryList);
}
