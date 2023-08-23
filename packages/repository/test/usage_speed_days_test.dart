import 'package:repository/ml/regressor.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleLinearRegressor', () {
    test('Should calculate Usage Rate Days correctly', () {
      Map<double, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch.toDouble(): 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0,
      };
      final simple = SimpleLinearRegressor(points);
      final regressor = NormalizedRegressor(simple, points);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });

  group('NaiveRegressor', () {
    test('Should calculate Usage Rate Days correctly', () {
      Map<double, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch.toDouble(): 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0,
      };
      final naive = NaiveRegressor.fromMap(points);
      final regressor = NormalizedRegressor(naive, points);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });

  group('HoltLinearRegressor', () {
    test('Should calculate Usage Rate Days correctly with alpha and beta', () {
      Map<double, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch.toDouble(): 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch.toDouble(): 0,
      };
      final holt = HoltLinearRegressor.fromMap(points, 0.9, 0.9);
      final regressor = NormalizedRegressor(holt, points);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });
}
