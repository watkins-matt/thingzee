import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
import 'package:repository/ml/scaler_map.dart';
import 'package:test/test.dart';

void main() {
  group('Normalized Regressor test:', () {
    test('WLS: Ensure predictions match original data.', () {
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
    test('WLS should work when only shifting baseTimestamp.', () {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };
      const baseTimestamp = 1687655897475.0;
      final shift = baseTimestamp - points.keys.first;
      final range = points.keys.last - points.keys.first;

      // Create and test the WLS regressor alone
      final weighted = WeightedLeastSquaresLinearRegressor(points);
      expect(weighted.predict(points.keys.first), closeTo(points.values.first, 0.1));
      expect(weighted.predict(points.keys.last), closeTo(points.values.last, 0.1));
      expect(weighted.predict(weighted.xIntercept), closeTo(0, 0.1));
      expect(weighted.slope, closeTo(-2.58e-10, 0.01));

      // Rescale the points
      Map<double, double> normalizedPoints = Map.from(points);
      MapNormalizer normalizer = MapNormalizer(normalizedPoints);
      normalizedPoints = normalizer.dataPoints;
      MapScaler scaler = MapScaler(Map.from(normalizedPoints), yScale: 1.5, baseX: baseTimestamp);
      Map<double, double> rescaledPoints = scaler.scaledDataPoints;

      // Create a correct regressor for verification
      final verifiedCorrectRegressor = WeightedLeastSquaresLinearRegressor(rescaledPoints);

      // The range should be the same
      expect(rescaledPoints.keys.last - rescaledPoints.keys.first, closeTo(range, 0.1));
      // The first key must be baseTimestamp since we shifted it
      // from 0 to baseTimestamp
      expect(rescaledPoints.keys.first, baseTimestamp);
      // The difference between the first keys should be the same as the shift
      expect(rescaledPoints.keys.first - points.keys.first, closeTo(shift, 0.1));

      // Create the normalized regressor
      final normalizedRegressor =
          NormalizedRegressor(weighted, points, baseTimestamp: baseTimestamp);

      // Formulas should match between the two regressors
      // Only take the first 24 characters to avoid rounding errors
      expect(normalizedRegressor.formula.substring(0, 24),
          verifiedCorrectRegressor.formula.substring(0, 24));

      // Slope should be the same regardless of the yShift.
      expect(normalizedRegressor.slope, closeTo(-2.58e-10, 0.1));

      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(0)),
          closeTo(points.values.first, 0.4));
      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(1)),
          closeTo(points.values.elementAt(1), 0.4));
      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(2)),
          closeTo(points.values.elementAt(2), 0.4));
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
      const baseAmount = 1.5;
      final normalizedRegressor = NormalizedRegressor(unnormalizedRegressor, points,
          baseTimestamp: baseTimestamp, yScale: baseAmount);

      expect(unnormalizedRegressor.slope, closeTo(normalizedRegressor.slope, 0.01));
      expect(unnormalizedRegressor.xIntercept, closeTo(normalizedRegressor.xIntercept, 0.01));
    });

    test('SimpleLinearRegressor should work when only shifting baseTimestamp.', () async {
      Map<double, double> points = {
        1687153789394: 1.5,
        1689472466876: 0.98,
        1692069900337: 0.2,
      };
      const baseTimestamp = 1687655897475.0;
      final shift = baseTimestamp - points.keys.first;
      final range = points.keys.last - points.keys.first;

      // Create and test the SL regressor alone
      final simple = SimpleLinearRegressor(points);
      expect(simple.predict(points.keys.first), closeTo(points.values.first, 0.1));
      expect(simple.predict(points.keys.last), closeTo(points.values.last, 0.1));
      expect(simple.predict(simple.xIntercept), closeTo(0, 0.1));
      expect(simple.slope, closeTo(-2.58e-10, 0.01));
      expect(simple.daysToXIntercept(points.keys.first),
          closeTo(simple.usageRateDays * points.values.first, 2));

      // Rescale the points
      Map<double, double> normalizedPoints = Map.from(points);
      MapNormalizer normalizer = MapNormalizer(normalizedPoints);
      normalizedPoints = normalizer.dataPoints;
      MapScaler scaler = MapScaler(Map.from(normalizedPoints), yScale: 1.5, baseX: baseTimestamp);
      Map<double, double> rescaledPoints = scaler.scaledDataPoints;

      // Create a correct regressor for verification
      final verifiedCorrectRegressor = SimpleLinearRegressor(rescaledPoints);

      // The range should be the same
      expect(rescaledPoints.keys.last - rescaledPoints.keys.first, closeTo(range, 0.1));
      // The first key must be baseTimestamp since we shifted it
      // from 0 to baseTimestamp
      expect(rescaledPoints.keys.first, baseTimestamp);
      // The difference between the first keys should be the same as the shift
      expect(rescaledPoints.keys.first - points.keys.first, closeTo(shift, 0.1));

      // Create the normalized regressor
      final normalizedRegressor = NormalizedRegressor(simple, points, baseTimestamp: baseTimestamp);

      // Formulas should match between the two regressors
      // Only take the first 24 characters to avoid rounding errors
      expect(normalizedRegressor.formula.substring(0, 24),
          verifiedCorrectRegressor.formula.substring(0, 24));

      // Slope should be the same regardless of the yShift.
      expect(normalizedRegressor.slope, closeTo(-2.58e-10, 0.1));

      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(0)),
          closeTo(points.values.first, 0.4));
      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(1)),
          closeTo(points.values.elementAt(1), 0.4));
      expect(normalizedRegressor.predict(rescaledPoints.keys.elementAt(2)),
          closeTo(points.values.elementAt(2), 0.4));
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
      MapScaler scaler =
          MapScaler(Map.from(normalizedPoints), yScale: 3, xScale: 3, baseX: 1692061933641);
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

    test('Scaling downward should work properly', () {
      final points = {
        1692061933641.0: 3.0,
        1692348065580.0: 2.8499999999999996,
        1693873987212.0: 1.7999999999999998,
        1696421709732.0: 0.0
      };
      const yScale = 1.0; // We are scaling to 1/3 of the original data

      final unnormalizedRegressor = SimpleLinearRegressor(points);
      final originalDaysToXIntercept = unnormalizedRegressor.daysToXIntercept(points.keys.first);

      final normalizedRegressor = NormalizedRegressor(unnormalizedRegressor, points,
          baseTimestamp: points.keys.first, yScale: yScale);
      expect(normalizedRegressor.yScaleProp, closeTo(yScale / points.values.first, 0.01));

      final normalizedDaysToXIntercept = normalizedRegressor.daysToXIntercept;
      expect(normalizedDaysToXIntercept,
          closeTo(originalDaysToXIntercept * normalizedRegressor.yScaleProp, 0.01));
    });
  });

  test('Values should always decrease from the original.', () {
    final points = {1701378720000.0: 0.5, 1704395220000.0: 0.15, 1705008420000.0: 0.0};

    const newTimestamp = 1707356040000.0;
    const firstPoint = 1.1;
    const futureTimestamp = newTimestamp + 2043792000.0;

    SpecificPointRegressor specificPointRegressor12 = SpecificPointRegressor(1, 2, points);
    SpecificPointRegressor specificPointRegressor02 = SpecificPointRegressor(0, 2, points);
    HoltLinearRegressor holtLinearRegressor = HoltLinearRegressor.fromMap(points, 0.75, 0.15);

    var normalizedRegressor = NormalizedRegressor(specificPointRegressor12, points,
        yScale: firstPoint, baseTimestamp: newTimestamp, startIndex: 1, endIndex: 2);
    var prediction = normalizedRegressor.predict(futureTimestamp);
    expect(prediction, lessThan(firstPoint));

    normalizedRegressor = NormalizedRegressor(specificPointRegressor02, points,
        yScale: firstPoint, baseTimestamp: newTimestamp, startIndex: 0, endIndex: 2);
    prediction = normalizedRegressor.predict(futureTimestamp);
    expect(prediction, lessThan(firstPoint));

    normalizedRegressor = NormalizedRegressor(holtLinearRegressor, points,
        yScale: firstPoint, baseTimestamp: newTimestamp);
    prediction = normalizedRegressor.predict(futureTimestamp);
    expect(prediction, lessThan(firstPoint));
  });
}
