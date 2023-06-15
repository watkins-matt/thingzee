import 'package:repository/ml/observation.dart';

class HistoryCSVRow {
  static int defaultHouseholdCount = 2;

  String upc = '';
  int seriesId = 0;
  double timestamp = 0;
  double amount = 0;
  int householdCount = defaultHouseholdCount;

  void loadFromRow(List<dynamic> row, Map<String, int> columnIndex) {
    final parsers = {
      'upc': (value) => upc = value.isNotEmpty ? value.normalizeUPC() : upc,
      'series_id': (value) => seriesId = value.isNotEmpty ? int.parse(value) : seriesId,
      'timestamp': (value) => timestamp = value.isNotEmpty ? double.parse(value) : timestamp,
      'amount': (value) => amount = value.isNotEmpty ? double.parse(value) : amount,
      'household_count': (value) =>
          householdCount = value.isNotEmpty ? int.parse(value) : householdCount,
    };

    // Parse every column that is present
    for (final parser in parsers.entries) {
      if (columnIndex.containsKey(parser.key)) {
        parser.value(row[columnIndex[parser.key]!].toString());
      }
    }
  }

  Observation toObservation() {
    return Observation(timestamp: timestamp, amount: amount, householdCount: householdCount);
  }

  static HistoryCSVRow? fromRow(List<dynamic> row, Map<String, int> columnIndex) {
    // Check if all required keys are present and return null otherwise
    const requiredKeys = ['upc', 'series_id', 'timestamp', 'amount'];
    if (!requiredKeys.every((key) => columnIndex.containsKey(key))) {
      return null;
    }

    HistoryCSVRow newRow = HistoryCSVRow();
    newRow.loadFromRow(row, columnIndex);

    return newRow;
  }
}
