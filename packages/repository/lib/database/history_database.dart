import 'package:quiver/core.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';

abstract class HistoryDatabase {
  List<History> all();
  void deleteAll();
  Optional<History> get(String upc);
  Map<String, Inventory> join(Map<String, Inventory> inventoryMap);
  List<Inventory> joinList(List<Inventory> inventoryList);
  Map<String, History> map();
  Set<String> predictedOuts(int days);
  void put(History history);
}
