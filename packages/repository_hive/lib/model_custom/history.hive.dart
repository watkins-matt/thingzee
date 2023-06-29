import 'package:hive/hive.dart';
import 'package:repository/ml/history.dart';

@HiveType(typeId: 2)
class HiveHistory extends HiveObject {
  @HiveField(0)
  String upc = '';

  @HiveField(1)
  History history;

  HiveHistory.from(this.history) {
    upc = history.upc;
  }

  History toHistory() {
    return history;
  }
}
