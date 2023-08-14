import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleLinearRegressor', () {
    test('Should calculate Usage Rate Days correctly', () {
      Map<int, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch: 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch: 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch: 0,
      };
      MapNormalizer normalizer = MapNormalizer(points);
      final simple = SimpleLinearRegressor(normalizer.dataPoints);
      final regressor = NormalizedRegressor.withBase(normalizer, simple, points.keys.first);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });

  group('NaiveRegressor', () {
    test('Should calculate Usage Rate Days correctly', () {
      Map<int, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch: 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch: 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch: 0,
      };
      MapNormalizer normalizer = MapNormalizer(points);
      final naive = NaiveRegressor.fromMap(normalizer.dataPoints);
      final regressor = NormalizedRegressor.withBase(normalizer, naive, points.keys.first);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });

  group('HoltLinearRegressor', () {
    test('Should calculate Usage Rate Days correctly with alpha and beta', () {
      Map<int, double> points = {
        DateTime.parse('2023-07-02 20:12:00').millisecondsSinceEpoch: 1.09,
        DateTime.parse('2023-07-09 20:33:00').millisecondsSinceEpoch: 0.93,
        DateTime.parse('2023-08-09 20:33:00').millisecondsSinceEpoch: 0,
      };
      MapNormalizer normalizer = MapNormalizer(points);
      final holt = HoltLinearRegressor.fromMap(normalizer.dataPoints, 0.9, 0.9);
      final regressor = NormalizedRegressor.withBase(normalizer, holt, points.keys.first);

      final usageRateDays =
          regressor.hasSlope ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24 : 0;

      expect(usageRateDays, greaterThanOrEqualTo(32));
      expect(usageRateDays, lessThanOrEqualTo(35));
    });
  });
}
