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
    test('Calculate slope and predict y-values correctly', () {
      // Initialize data
      Map<double, double> data = {
        1686625527727: 0.5, // Jun 12, 2023 8:05 PM
        1686844388101: 0.35, // Jun 15, 2023 8:53 AM
      };

      // Get normalized points
      var x1 = data.keys.elementAt(0);
      var y1 = data.values.elementAt(0);
      var x2 = data.keys.elementAt(1);
      var y2 = data.values.elementAt(1);

      // Calculate slope and intercept
      var tpRegressor = TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2);
      var regressor = NormalizedRegressor(tpRegressor, {x1: y1, x2: y2});
      // Check slope
      expect(regressor.slope, closeTo(-6.853684714986369e-10, 1e-2));

      var prediction = regressor.predict(1687355062307);
      expect(prediction, closeTo(0, 1e-2));
      expect(regressor.xIntercept, closeTo(1687355062307, 1e-2));

      // Test shifting everything by this amount
      const lastOutageTimestamp = 1687355062307;
      const relativeOutageTimestamp = lastOutageTimestamp - 1686625527727;
      const offsetShiftAmount = 1687360000000.0;

      regressor = NormalizedRegressor(tpRegressor, data, baseTimestamp: offsetShiftAmount);
      const newOutageTimestamp = offsetShiftAmount + relativeOutageTimestamp;

      // Slope should still be the same
      expect(regressor.slope, closeTo(-6.853684714986369e-10, 1e-2));

      // Shifted prediction should be the same
      prediction = regressor.predict(newOutageTimestamp);
      expect(prediction, closeTo(0, 1e-2));
      expect(regressor.xIntercept, closeTo(newOutageTimestamp, 1e-2));
    });

    test('Unnormalized: calculate slope and predict y-values correctly', () {
      // Initialize data
      Map<double, double> data = {
        1686625527727: 0.5, // Jun 12, 2023 8:05 PM
        1686844388101: 0.35, // Jun 15, 2023 8:53 AM
      };

      // Calculate slope and intercept using unnormalized data
      var regressor = TwoPointLinearRegressor.fromPoints(data.keys.elementAt(0),
          data.values.elementAt(0), data.keys.elementAt(1), data.values.elementAt(1));

      // Check slope
      expect(regressor.slope, closeTo(-6.853684714986369e-10, 1e-20));

      var prediction = regressor.predict(1687355062307);
      expect(prediction, closeTo(0, 1e-2));
      expect(regressor.xIntercept, closeTo(1687355062307, 1e-2));
    });
  });
}
