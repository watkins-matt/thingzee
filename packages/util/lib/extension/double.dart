import 'dart:math';

import 'package:intl/intl.dart';

extension Round on double {
  double roundTo(int places) {
    if (this == double.infinity || this == double.negativeInfinity) {
      throw UnsupportedError('roundTo can only round real numbers.');
    }
    assert(places >= 0);

    double value = this * pow(10, places);
    value = value.roundToDouble();
    value /= pow(10, places);
    return value;
  }

  String toStringNoZero(int places) {
    final formatter = NumberFormat();
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = places;
    return formatter.format(this);
  }
}
