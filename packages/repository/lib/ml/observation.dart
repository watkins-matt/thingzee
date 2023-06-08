import 'package:json_annotation/json_annotation.dart';
import 'package:repository/ml/date_time.dart';
import 'package:repository/ml/normalizer.dart';

part 'observation.g.dart';

@JsonSerializable()
class Observation {
  final double timestamp;
  final double amount;
  final int weekday;
  final double timeOfYearSin;
  final double timeOfYearCos;
  final int householdCount;

  static List<String> header = [
    'timestamp',
    'amount',
    // 'weekday_0',
    // 'weekday_1',
    // 'weekday_2',
    // 'weekday_3',
    // 'weekday_4',
    // 'weekday_5',
    // 'weekday_6',
    // 'timeOfYear_sin',
    // 'timeOfYear_cos',
    // 'householdCount',
  ];

  Observation({
    required this.timestamp,
    required this.amount,
    required this.householdCount,
  })  : weekday = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).weekday,
        timeOfYearSin = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).timeOfYear[0],
        timeOfYearCos = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).timeOfYear[1];

  factory Observation.fromJson(Map<String, dynamic> json) => _$ObservationFromJson(json);
  Map<String, dynamic> toJson() => _$ObservationToJson(this);

  MapEntry<int, double> toPoint() {
    return MapEntry(timestamp.toInt(), amount);
  }

  List<double> toList() {
    // Convert weekday to one-hot encoding
    final weekdayEncoding = List<double>.filled(7, 0);
    weekdayEncoding[weekday - 1] = 1.0;

    return [
      timestamp,
      amount,
      // ...weekdayEncoding,
      // timeOfYearSin,
      // timeOfYearCos,
      // householdCount,
    ];
  }

  List<double> normalize(Normalizer normalizer) {
    return [
      normalizer.normalizeValue('timestamp', timestamp),
      amount,
      // normalizer.normalizeValue('timeOfYear_sin', timeOfYearSin),
      // normalizer.normalizeValue('timeOfYear_cos', timeOfYearCos),
    ];
  }
}
