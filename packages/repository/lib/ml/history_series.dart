import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:repository/ml/observation.dart';

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
}
