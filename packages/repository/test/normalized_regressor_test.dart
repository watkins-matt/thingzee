import 'package:repository/ml/normalizer_map.dart';
import 'package:repository/ml/regressor.dart';
import 'package:test/test.dart';

void main() {
  group('Normalized Regressor test:', () {
    test('Values should be as expected.', () async {
      final Map<int, double> points = {
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
      final Map<int, double> points = {1687068097311: 0.05, 1687227951884: 0.02, 1687567689462: 0};

      MapNormalizer normalizer = MapNormalizer(points);
      final weighted = WeightedLeastSquaresLinearRegressor(normalizer.dataPoints);
      var regressor = NormalizedRegressor(normalizer, weighted);

      expect(regressor.predict(1687567689462), closeTo(0, 0.1));

      const baseTimestamp = 1687655897475;
      const timestampToPredict = 1687661141416;
      regressor = NormalizedRegressor.withBase(normalizer, regressor, baseTimestamp);

      print(regressor.predict(timestampToPredict));
    });
  });
}
