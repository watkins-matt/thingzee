import 'package:hive/hive.dart';
import 'package:repository/ml/history.dart';

part 'history.hive.g.dart';

@HiveType(typeId: 223)
class HiveHistory extends HiveObject {
  @HiveField(0)
  String upc = '';

  @HiveField(1)
  History history = History();

  HiveHistory();
  HiveHistory.from(this.history) {
    upc = history.upc;
  }

  History toHistory() {
    return history;
  }
}
