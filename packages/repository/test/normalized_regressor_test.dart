import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
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

      MapNormalizer normalizer = MapNormalizer(points);
      final weighted = WeightedLeastSquaresLinearRegressor(normalizer.dataPoints);
      var regressor = NormalizedRegressor(normalizer, weighted);

      expect(regressor.predict(1687567689462), closeTo(0, 0.1));
      expect(regressor.slope, closeTo(-9.363299158029206e-11, 0.1));

      const baseTimestamp = 1687655897475.0;
      regressor = NormalizedRegressor.withBase(normalizer, weighted, baseTimestamp, yShift: 1);

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

      // Normalizing the points
      MapNormalizer normalizer = MapNormalizer(points);
      points = normalizer.dataPoints;

      // Creating NaiveRegressor wrapped with NormalizedRegressor
      final naive = NaiveRegressor.fromMap(points);
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.5;
      final regressor =
          NormalizedRegressor.withBase(normalizer, naive, baseTimestamp, yShift: baseAmount);

      // Checking the xIntercept
      final xIntercept = regressor.xIntercept;
      expect(xIntercept, isNotNull); // Replace with expected value if known

      // Verifying that the value of regressor.predict at the xIntercept time is 0
      final predictionAtXIntercept = regressor.predict(xIntercept);
      expect(predictionAtXIntercept, closeTo(0, 0.01));
    });

    test('SimpleLinearRegressor with NormalizedRegressor', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };

      // Normalizing the points
      MapNormalizer normalizer = MapNormalizer(points);
      points = normalizer.dataPoints;

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      final naive = SimpleLinearRegressor(points);
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.5;
      final regressor =
          NormalizedRegressor.withBase(normalizer, naive, baseTimestamp, yShift: baseAmount);

      // Checking the xIntercept
      final xIntercept = regressor.xIntercept;
      expect(xIntercept, isNotNull); // Replace with expected value if known

      // Verifying that the value of regressor.predict at the xIntercept time is 0
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

      // Checking the xIntercept
      final xIntercept = regressor.xIntercept;
      expect(xIntercept, isNotNull); // Replace with expected value if known

      // Verifying that the value of regressor.predict at the xIntercept time is 0
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

      // Create the normalized points
      Map<double, double> normalizedPoints = Map.from(points);
      MapNormalizer normalizer = MapNormalizer(normalizedPoints);
      normalizedPoints = normalizer.dataPoints;

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      final regressor = SimpleLinearRegressor(normalizedPoints);
      const baseTimestamp = 1687153789394.0;
      const baseAmount = 1.5;
      final normalizedRegressor =
          NormalizedRegressor.withBase(normalizer, regressor, baseTimestamp, yShift: baseAmount);

      expect(unnormalizedRegressor.slope, closeTo(normalizedRegressor.slope, 0.01));
      expect(unnormalizedRegressor.xIntercept, closeTo(normalizedRegressor.xIntercept, 0.01));

      print(unnormalizedRegressor.formula);
      print(normalizedRegressor.formula);
    });

    test('Compare usageRateDays between normalized and unnormalized regressors.', () {
      Map<double, double> points = {
        1686184734424: 1.0,
        1686280111737: 0.95,
        1686788752281: 0.6,
        1687637993121: 0.0,
      };
      final unnormalizedRegressor = SimpleLinearRegressor(points);
      print(unnormalizedRegressor.predict(1686184734424)); // approx 1
      print(unnormalizedRegressor.predict(1687637993121)); // approx 0
      print(unnormalizedRegressor.predict(1686911363772.5)); // approx 0.5
      print(unnormalizedRegressor.predict(unnormalizedRegressor.xIntercept)); // exact 0

      final originalUsageRateDays = unnormalizedRegressor.usageRateDays;
      print('Original usageRateDays: $originalUsageRateDays');

      // Create the normalized points
      Map<double, double> normalizedPoints = Map.from(points);
      MapNormalizer normalizer = MapNormalizer(normalizedPoints);
      normalizedPoints = normalizer.dataPoints;

      // Creating SimpleLinearRegressor wrapped with NormalizedRegressor
      final regressor = SimpleLinearRegressor(normalizedPoints);
      const baseTimestamp = 1692061933641.0;
      const baseAmount = 3.0;
      final normalizedRegressor =
          NormalizedRegressor.withBase(normalizer, regressor, baseTimestamp, yShift: baseAmount);
      final daysToXIntercept = (normalizedRegressor.xIntercept - baseTimestamp) / 86400000;
      print('daysToXIntercept: $daysToXIntercept');
      print('xIntercept: ${normalizedRegressor.xIntercept}');

      const targetXIntercept = 1696393769585.49;
      final actualXIntercept = normalizedRegressor.xIntercept;
      final difference = (actualXIntercept - targetXIntercept).abs();
      print(difference);

      var halfWayTimestampOriginal = targetXIntercept - baseTimestamp;
      halfWayTimestampOriginal /= 2;
      halfWayTimestampOriginal += baseTimestamp;

// Predict the amount at this timestamp using the normalized regressor
      final halfWayAmountNormalized = normalizedRegressor.predict(halfWayTimestampOriginal);
      print(halfWayAmountNormalized);

      print(normalizedRegressor.predict(normalizedRegressor.xIntercept));
      print(normalizedRegressor.predict(targetXIntercept));

      expect(daysToXIntercept, closeTo(originalUsageRateDays * 3, 0.6));
    });
  });
}
