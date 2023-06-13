import 'package:repository/ml/ml_history.dart';
import 'package:repository/ml/regressor.dart';
import 'package:test/test.dart';

void main() {
  const int minOffset = 86400000;
  group('MLHistory:', () {
    test('should ensure that values added are at least 24 hours apart.', () async {
      MLHistory history = MLHistory();
      history.add(1, 100, 2);
      history.add(2, 90, 2);
      history.add(minOffset + 2, 80, 2);
      history.add(minOffset + 3, 80, 2);
      history.add(minOffset + 3, 79, 2);

      expect(history.current.observations.length, 2);
      expect(history.current.observations[0].timestamp, 2);
      expect(history.current.observations[1].timestamp, minOffset + 3);
    });

    test('Regression of two points should match expected values.', () async {
      MLHistory history = MLHistory();
      history.add(1640995200000, 10, 2);
      history.add(1641081600000, 6, 2);
      TwoPointLinearRegressor regressor = history.current.regressor as TwoPointLinearRegressor;

      expect(regressor.yIntercept, closeTo(75982, 1e-5));
      expect(regressor.slope, closeTo(-4.62963e-8, 1e-13));
    });

    test('Regression with three points', () {
      MLHistory history = MLHistory();
      history.add(1 * 86400000, 4, 2); // Day 1
      history.add(3 * 86400000, 3, 2); // Day 3
      history.add(5 * 86400000, 2, 2); // Day 5

      var regressor = history.current.regressor;
      var predictedAmounts =
          history.current.observations.map((o) => regressor.predict(o.timestamp.toInt())).toList();

      expect(predictedAmounts[0], closeTo(4, 0.1));
      expect(predictedAmounts[1], closeTo(3, 0.1));
      expect(predictedAmounts[2], closeTo(2, 0.1));
    });
  });
}
