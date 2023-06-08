import 'package:json_annotation/json_annotation.dart';
import 'package:stats/stats.dart';

part 'history.g.dart';

typedef Series = Map<int, double>;

@JsonSerializable()
class History {
  List<Series> series = [];

  History();

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryToJson(this);

  // Remove any empty series values in the history
  History trim() {
    for (int i = 0; i < series.length; i++) {
      if (series[i].isEmpty) {
        series.removeAt(i);
        return trim();
      }
    }

    return this;
  }

  int get totalPoints {
    int count = 0;

    for (final set in series) {
      count += set.length;
    }

    return count;
  }

  double get averageRegression {
    if (series.isEmpty) return 0;

    double reg = 0;
    for (final set in series) {
      reg += set.regression;
    }

    reg /= series.length;
    return reg;
  }

  Series get previous {
    return series.length > 1 ? series[series.length - 2] : current;
  }

  Series get current {
    return series.isNotEmpty ? series.last : {};
  }

  double get currentSeriesRegression {
    double reg = 0;

    if (current.length > 1) {
      reg = current.regression;
      // There's only one item in this series, use the previous regression
    } else if (series.length > 1) {
      reg = previous.regression;
    }

    return reg;
  }

  bool get hasIntercept {
    return xIntercept != 0 && !xIntercept.isNaN && !xIntercept.isInfinite;
  }

  double get xIntercept {
    double x = 0;

    if (current.regression != 0) {
      x = current.xIntercept;
    } else {
      double reg = currentSeriesRegression;
      if (reg != 0 && current.isNotEmpty) {
        double b = current.yInterceptWithSlope(reg);
        x = (0 - b) / reg;
      } else {
        double b = previous.yInterceptWithSlope(reg);
        x = (0 - b) / reg;
      }
    }

    return x;
  }

  double predict(double x) {
    double y = 0;

    if (current.regression != 0) {
      y = current.predict(x);
    } else {
      double reg = currentSeriesRegression;
      if (reg != 0) {
        double b = current.yInterceptWithSlope(reg);
        y = (reg * x) + b;
      }
    }

    return y;
  }

  void add(int timestamp, double level, [bool enforceMinimumOffset = false]) {
    // There are other values, check for dupes
    if (current.isNotEmpty) {
      double lastTimestamp = current.last;

      assert(current.containsKey(lastTimestamp));
      // Timestamps must be added in order, we cannot add timestamps from the past
      if (timestamp <= lastTimestamp) {
        // Remove the last timestamp that is likely wrong
        current.remove(lastTimestamp);
        // Recursively call add, ensuring that any other wrong timestamps are also removed
        add(timestamp, level, enforceMinimumOffset);
        // We added the timestamp in the recursive call, return
        return;
      }

      double lastValue = current[lastTimestamp]!;

      // If we increased in value, we need to start a new series,
      // and add in the predicted last value for the last series
      if (level > lastValue) {
        // We had a predicted out date, make that the zero
        if (xIntercept.isFinite && xIntercept != 0) {
          // The predicted timestamp was earlier than the new timestamp, we can use it
          if (xIntercept < timestamp) {
            current[xIntercept.round()] = 0;
          } else {
            // Don't add a new timestamp because it will throw off the calculations.
            // We can still calculate from prior history points.
          }
        }

        // If we've got a series with only one value, clean up the series
        // and continue using it, discarding the old value
        if (current.length == 1) {
          current.clear();
          current[timestamp] = level;
        } else {
          series.add({});
          current[timestamp] = level;
        }
      }

      // This level was the same as the last
      else if (level == lastValue) {
        // We could push the timestamp forward, but this creates issues because
        // users may frequently update other parts of a product description
        // current.remove(lastTimestamp);
        // current[timestamp] = level;
      }

      // This level was different and a decrease in value, we should add it
      else {
        double offset = timestamp - lastTimestamp;
        const double minOffset = 86400000; // 24 hours in milliseconds

        // We are within the minimum offset, remove the last recent point and proceed
        // with code to add the new point, essentially pushing the timestamp forward with
        // the new decrease. This helps prevent extreme changes in the regression value.
        if (enforceMinimumOffset && offset < minOffset) {
          current.remove(lastTimestamp);

          // We tried to zero an item within 24 hours, don't add this point
          // because it will skew data and return
          if (level <= 0) {
            return;
          }
        }

        // The user was trying to set the value to zero
        if (level <= 0) {
          // We had a predicted timestamp that we went to zero, use that as the correct one
          // DO NOT add timestamps in the future because this will cause all sorts of problems.
          if (xIntercept.isFinite && xIntercept != 0 && xIntercept <= timestamp) {
            current[xIntercept.round()] = 0;
          }

          // There was not a predicted time to go to zero, just add this point like normal
          else {
            current[timestamp] = level;
          }
        }

        // Above zero, add the point like normal
        else {
          current[timestamp] = level;
        }
      }
    }

    // There weren't any other values, add this one as the first
    else {
      current[timestamp] = level;
    }
  }
}
