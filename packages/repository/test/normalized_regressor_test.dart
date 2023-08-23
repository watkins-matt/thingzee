import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
import 'package:repository/ml/scaler_map.dart';
import 'package:test/test.dart';

void main() {
  group('Normalized Regressor test:', () {
    test('WLS: Ensure predictions match original data.', () async {
      final Map<double, double> points = {
        1686280709794: 2.5,
        1686389999245: 2.2,
        1686525359796: 2.1,
        1686631400447: 2.0,
        1686791671192: 1.3,
        1686929156394: 0.75,
      };

      MapNormalizer normalizer = MapNormalizer(points);
      final weighted = WeightedLeastSquaresLinearRegressor(points);
      // ignore: unused_local_variable
      const base = 1687067165106;

      // final regressor = NormalizedRegressor(normalizer, weighted);
      final weightedSecond = WeightedLeastSquaresLinearRegressor(normalizer.dataPoints);

      expect(weighted.predict(1686280709794), closeTo(2.5, 0.1));
      expect(weightedSecond.predict(0), closeTo(1, 0.1));
    });
    test('WLS should work with 3 values.', () async {
      final Map<double, double> points = {
        1687068097311: 0.05,
        1687227951884: 0.02,
        1687567689462: 0
      };

      final weighted = WeightedLeastSquaresLinearRegressor(points);
      var regressor = NormalizedRegressor(weighted, points);

      expect(regressor.predict(1687567689462), closeTo(0, 0.1));
      expect(regressor.slope, closeTo(-9.363299158029206e-11, 0.1));

      const baseTimestamp = 1687655897475.0;
      regressor = NormalizedRegressor(weighted, points, baseTimestamp: baseTimestamp);

      // Slope should be the same regardless of the yShift.
      expect(regressor.slope, closeTo(-9.363299158029206e-11, 0.1));

      const firstRelativeTimestamp = baseTimestamp + 159854573;
      const secondRelativeTimestamp = baseTimestamp + 499592151;

      expect(regressor.predict(baseTimestamp), closeTo(2, 0.4));
      expect(regressor.predict(firstRelativeTimestamp), closeTo(0.8, 0.4));
      expect(regressor.predict(secondRelativeTimestamp), closeTo(0, 0.4));
    });
    test('NaiveRegressor with NormalizedRegressor', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };

      final naive = NaiveRegressor.fromMap(points);
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.5;
      final regressor =
          NormalizedRegressor(naive, points, baseTimestamp: baseTimestamp, yScale: baseAmount);

      // Verify that the value at the x intercept should be equal to 0
      final xIntercept = regressor.xIntercept;
      final predictionAtXIntercept = regressor.predict(xIntercept);
      expect(predictionAtXIntercept, closeTo(0, 0.01));
    });

    test('SimpleLinearRegressor with NormalizedRegressor', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      final simple = SimpleLinearRegressor(points);
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.5;
      final regressor =
          NormalizedRegressor(simple, points, baseTimestamp: baseTimestamp, yScale: baseAmount);

      // Verify that the value at the x intercept should be equal to 0
      final xIntercept = regressor.xIntercept;
      final predictionAtXIntercept = regressor.predict(xIntercept);
      expect(predictionAtXIntercept, closeTo(0, 0.01));
    });

    test('SimpleLinearRegressor without NormalizedRegressor', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      final regressor = SimpleLinearRegressor(points);

      // Verify that the value at the x intercept should be equal to 0
      final xIntercept = regressor.xIntercept;
      final predictionAtXIntercept = regressor.predict(xIntercept);
      expect(predictionAtXIntercept, closeTo(0, 0.01));
    });

    test(
        'Normalized and unnormalized regressors should agree'
        ' when converting back to the same terms.', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };
      final unnormalizedRegressor = SimpleLinearRegressor(points);

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.0;
      final normalizedRegressor = NormalizedRegressor(unnormalizedRegressor, points,
          baseTimestamp: baseTimestamp, yScale: baseAmount);

      expect(unnormalizedRegressor.slope, closeTo(normalizedRegressor.slope, 0.01));
      expect(unnormalizedRegressor.xIntercept, closeTo(normalizedRegressor.xIntercept, 0.01));
    });

    test('Compare usageRateDays between normalized and unnormalized regressors.', () {
      Map<double, double> points = {
        1686184734424: 1.0,
        1686280111737: 0.95,
        1686788752281: 0.6,
        1687637993121: 0.0,
      };

      const baseTimestamp = 1692061933641.0;
      const baseAmount = 3.0;

      final unnormalizedRegressor = SimpleLinearRegressor(points);
      final originalUsageRateDays = unnormalizedRegressor.usageRateDays;

      // Create the normalized points
      Map<double, double> normalizedPoints = Map.from(points);
      MapNormalizer normalizer = MapNormalizer(normalizedPoints);
      normalizedPoints = normalizer.dataPoints;
      MapScaler scaler = MapScaler(Map.from(normalizedPoints), 3, 1692061933641);
      Map<double, double> rescaledPoints = scaler.scaledDataPoints;

      // Use this regressor to verify other regressors
      final verifiedCorrectRegressor = SimpleLinearRegressor(rescaledPoints);
      final correctDaysToXIntercept = verifiedCorrectRegressor.daysToXIntercept(baseTimestamp);

      expect(correctDaysToXIntercept, closeTo(originalUsageRateDays * baseAmount, 0.6));
      expect(
          verifiedCorrectRegressor.predict(verifiedCorrectRegressor.xIntercept), closeTo(0, 0.1));
      expect(verifiedCorrectRegressor.predict(baseTimestamp), closeTo(baseAmount, 0.1));

      // Create the normalized regressor
      final normalizedRegressor = NormalizedRegressor(unnormalizedRegressor, points,
          baseTimestamp: baseTimestamp, yScale: baseAmount);
      final normalizedDaysToXIntercept = normalizedRegressor.daysToXIntercept;

      expect(normalizedDaysToXIntercept, closeTo(originalUsageRateDays * baseAmount, 0.6));
      expect(normalizedRegressor.predict(normalizedRegressor.xIntercept), closeTo(0, 0.1));
      expect(normalizedRegressor.predict(baseTimestamp), closeTo(baseAmount, 0.1));

      // Formulas should match between the two regressors
      // Only take the first 24 characters to avoid rounding errors
      expect(normalizedRegressor.formula.substring(0, 24),
          verifiedCorrectRegressor.formula.substring(0, 24));
    });
  });
}
