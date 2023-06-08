// ignore_for_file: avoid_print

import 'package:stats/stats.dart';
import 'package:test/test.dart';

void main() {
  test('Test that formula is working.', () {
    Map<int, double> points = {8: 3, 2: 10, 11: 3, 6: 6, 5: 8, 4: 12, 12: 1, 9: 4, 1: 14};
    print(points.regression);
    print(points.yIntercept);
    print(points.predict(8));
    print(points.predict(11));
    print(points.xIntercept);
    print(points.yIntercept);

    Map<int, double> points2 = {1: 2.0, 2: 4.0, 3: 5.0};
    print(points2.regression);
    print(points2.x.mean);
    print(points2.y.mean);
    print(points2.getFormula());
  });
}
