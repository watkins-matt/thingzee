import 'package:repository/ml/observation.dart';
import 'package:repository/model/item.dart';

class HistoryCSVRow {
  static int defaultHouseholdCount = 2;
  String upc;
  int seriesId;
  double timestamp;
  double amount;

  int householdCount;

  HistoryCSVRow._(this.upc, this.seriesId, this.timestamp, this.amount, this.householdCount);

  Observation toObservation() {
    return Observation(timestamp: timestamp, amount: amount, householdCount: householdCount);
  }

  static HistoryCSVRow? fromRow(List<dynamic> row, Map<String, int> columnIndex) {
    if (!columnIndex.containsKey('upc') ||
        !columnIndex.containsKey('series_id') ||
        !columnIndex.containsKey('timestamp') ||
        !columnIndex.containsKey('amount')) {
      return null;
    }

    // All of these columns must be present to be valid
    String upc = row[columnIndex['upc']!].toString().normalizeUPC();
    int seriesId = int.parse(row[columnIndex['series_id']!].toString());
    double timestamp = double.parse(row[columnIndex['timestamp']!].toString());
    double amount = double.parse(row[columnIndex['amount']!].toString());

    // We can use a default household count if it's not present
    int householdCount = columnIndex.containsKey('household_count')
        ? int.parse(row[columnIndex['household_count']!].toString())
        : defaultHouseholdCount;

    return HistoryCSVRow._(upc, seriesId, timestamp, amount, householdCount);
  }
}
