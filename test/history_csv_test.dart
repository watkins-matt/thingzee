import 'package:flutter_test/flutter_test.dart';
import 'package:thingzee/data/history_csv_row.dart';

void main() {
  group('HistoryCSVRow', () {
    test('fromRow should return null if any required field is missing', () {
      final row = ['123', '1', '1500', '2.0'];
      final headers = {'upc': 0, 'series_id': 1, 'timestamp': 2};
      final historyRow = HistoryCSVRow.fromRow(row, headers);
      expect(historyRow, isNull);
    });

    test('fromRow should return a HistoryCSVRow if all required fields are present', () {
      final row = ['123', '1', '1500', '2.0'];
      final headers = {'upc': 0, 'series_id': 1, 'timestamp': 2, 'amount': 3};
      final historyRow = HistoryCSVRow.fromRow(row, headers);
      expect(historyRow, isNotNull);
      expect(historyRow?.upc, equals('123'));
      expect(historyRow?.seriesId, equals(1));
      expect(historyRow?.timestamp, equals(1500.0));
      expect(historyRow?.amount, equals(2.0));
    });
  });
}
