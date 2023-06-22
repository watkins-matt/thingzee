import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
import 'package:test/test.dart';

void main() {
  group('TwoPointLinearRegressor', () {
    test('Calculates slope and intercept correctly', () {
      var regressor = TwoPointLinearRegressor.fromPoints(1, 2, 3, 4);
      expect(regressor.slope, equals(1.0));
      expect(regressor.yIntercept, equals(1.0));
    });

    test('Predicts y-values correctly', () {
      var regressor = TwoPointLinearRegressor.fromPoints(1, 2, 3, 4);
      expect(regressor.predict(5), equals(6.0));
    });
  });

  group('MapNormalizer', () {
    test('Normalizes and denormalizes time correctly', () {
      var normalizer = MapNormalizer({1: 2, 3: 4});
      expect(normalizer.normalizeTime(1), equals(0));
      expect(normalizer.denormalizeTime(0), equals(1));
    });

    test('Normalizes and denormalizes amount correctly', () {
      var normalizer = MapNormalizer({1: 2, 3: 4});
      expect(normalizer.normalizeAmount(2), equals(0.5));
      expect(normalizer.denormalizeAmount(0.5), equals(2));
    });
  });

  group('TwoPointLinearRegressor and MapNormalizer', () {
    test('calculate slope and predict y-values correctly', () {
      // Initialize data
      var data = {
        1686625527727: 0.5, // Jun 12, 2023 8:05 PM
        1686844388101: 0.35, // Jun 15, 2023 8:53 AM
      };

      // Normalize data
      var normalizer = MapNormalizer(data);
      var normalizedData = normalizer.dataPoints;

      // Get normalized points
      var x1 = normalizedData.keys.elementAt(0);
      var y1 = normalizedData.values.elementAt(0);
      var x2 = normalizedData.keys.elementAt(1);
      var y2 = normalizedData.values.elementAt(1);

      // Calculate slope and intercept
      var regressor = TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2);
      regressor.scaleFactor.value = normalizer.maxAmount;

      // Check slope
      expect(regressor.slope, closeTo(-6.853684714986369e-10, 1e-20));

      // Predict y-value for Jun 19, 2023 7:25 PM
      var prediction = regressor.predict(1698039900000 - normalizer.minTime);
      expect(prediction, closeTo(0.02, 1e-2));
    });
  });
}
