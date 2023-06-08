import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/ml/regressor.dart';

part 'history_series.g.dart';

@JsonSerializable(explicitToJson: true)
class HistorySeries {
  List<Observation> observations = [];
  HistorySeries();

  int get minTimestamp {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.timestamp.toInt()).reduce(min);
  }

  int get maxTimestamp {
    if (observations.isEmpty) {
      return 0;
    }
    return observations.map((o) => o.timestamp.toInt()).reduce(max);
  }

  factory HistorySeries.fromJson(Map<String, dynamic> json) => _$HistorySeriesFromJson(json);
  Map<String, dynamic> toJson() => _$HistorySeriesToJson(this);

  DataFrame toDataFrame() {
    final data = observations.map((o) => o.toList()).toList();
    return DataFrame(data, headerExists: false, header: Observation.header);
  }

  Map<int, double> toPoints() {
    return observations.fold({}, (map, o) {
      map[o.timestamp.toInt()] = o.amount;
      return map;
    });
  }

  Regressor get regressor {
    switch (observations.length) {
      case 0:
        return EmptyRegressor();
      case 1:
        return SingleDataPointLinearRegressor(observations[0].amount);
      case 2:
        var x1 = observations[0].timestamp.toInt();
        var y1 = observations[0].amount;
        var x2 = observations[1].timestamp.toInt();
        var y2 = observations[1].amount;
        return TwoPointLinearRegressor.fromPoints(x1, y1, x2, y2);
      default:
        final points = toPoints();
        return SimpleLinearRegressor(points);
      // return NaiveRegressor.fromMap(points);
      // return HoltLinearRegressor.fromMap(points, .85, .75);

      // final dataFrame = toDataFrame();
      // final normalizer = Normalizer(dataFrame, 'amount');

      // Using the OLS Model
      // final regressor = OLSRegressor();
      // regressor.fit(normalizer.dataFrame, 'amount');
      // return SimpleOLSRegressor(regressor, normalizer);

      // Using the SGD Model
      // final regressor = LinearRegressor.SGD(normalizer.dataFrame, 'amount',
      //     fitIntercept: true,
      //     interceptScale: .25,
      //     iterationLimit: 5000,
      //     initialLearningRate: 1,
      //     learningRateType: LearningRateType.constant);
      // return MLLinearRegressor(regressor, normalizer);
    }
  }
}
