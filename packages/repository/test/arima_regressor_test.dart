import 'package:ml_linalg/linalg.dart';
import 'package:repository/ml/arima_regressor.dart';
import 'package:test/test.dart';

void main() {
  var arima = ArimaRegressor(1, 0);

  var differenceTestCases = [
    {
      'series': Vector.fromList([1, 2, 3, 4]),
      'order': 1,
      'expected': Vector.fromList([1, 1, 1])
    },
    {
      'series': Vector.fromList([1, 2, 4, 8]),
      'order': 2,
      'expected': Vector.fromList([1, 2])
    },
    {
      'series': Vector.fromList([1, 2, 3, 4]),
      'order': 0,
      'expected': Vector.fromList([1, 2, 3, 4])
    },
    {
      'series': Vector.fromList([1]),
      'order': 1,
      'expected': Vector.empty()
    },
    {'series': Vector.empty(), 'order': 1, 'expected': Vector.empty()},
  ];
  var undifferenceTestCases = [
    {
      'value': 5.0,
      'series': Vector.fromList([1, 2, 3, 4]),
      'order': 1,
      'expected': 9.0
    },
    {
      'value': -2.0,
      'series': Vector.fromList([1, 2, 4, 8]),
      'order': 2,
      'expected': -6.0
    },
    {
      'value': -3.0,
      'series': Vector.fromList([1]),
      'order': 0,
      'expected': -3.0
    },
    // {'value': -3.0, 'series': Vector.empty(), 'order': 0, 'expected': -3.0},
    // {'value': -3.0, 'series': Vector.empty(), 'order': 1, 'expected': -3.0},
  ];

  var autocorrTestCases = [
    {
      'series': Vector.fromList([1, -2, -3]),
      'lag': 0,
      'expected': 1.0
    },
    {
      'series': Vector.fromList([1, -2, -3]),
      'lag': 1,
      'expected': -0.051,
    },
    {
      'series': Vector.fromList([1, -2, -3]),
      'lag': 2,
      'expected': -0.449,
    },
    // {
    //   'series': Vector.fromList([1]),
    //   'lag': 0,
    //   'expected': double.nan
    // },
    // {'series': Vector.empty(), 'lag': 0, 'expected': double.nan},
  ];

  group('difference', () {
    for (final testCase in differenceTestCases) {
      test(
          'Should return ${testCase['expected']} when series is ${testCase['series']} and order is ${testCase['order']}',
          () {
        var actual = arima.difference(testCase['series'] as Vector, testCase['order'] as int);
        expect(actual, equals(testCase['expected']));
      });
    }
  });

  group('undifference', () {
    for (final testCase in undifferenceTestCases) {
      test(
          'Should return ${testCase['expected']} when value is ${testCase['value']}, series is ${testCase['series']} and order is ${testCase['order']}',
          () {
        var actual = arima.undifference(
            testCase['value'] as double, testCase['series'] as Vector, testCase['order'] as int);
        expect(actual, equals(testCase['expected']));
      });
    }
  });

  group('autocorr', () {
    for (final testCase in autocorrTestCases) {
      test(
          'Should return close to ${testCase['expected']} when series is ${testCase['series']} and lag is ${testCase['lag']}',
          () {
        var actual = (testCase['series'] as Vector).autocorr()[testCase['lag'] as int];
        expect(
            actual,
            (testCase['expected'] as double).isNaN
                ? double.nan
                : closeTo(testCase['expected'] as double, 0.001)); // delta set to 0.001
      });
    }
  });
}
