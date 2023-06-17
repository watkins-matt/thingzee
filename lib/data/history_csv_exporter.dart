import 'package:csv/csv.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/csv_exporter.dart';

class HistoryCSVExporter implements CSVExporter {
  @override
  List<String> get headers => [
        'upc',
        'series_id',
        'timestamp',
        'amount',
        'weekday',
        'time_of_year_sin',
        'time_of_year_cos',
        'household_count'
      ];

  @override
  Future<String> export(Repository r) async {
    List<List<dynamic>> rows = [headers];

    List<MLHistory> allHistory = r.hist.all();

    for (final history in allHistory) {
      rows.addAll(history.toCSVList(headers));
    }

    return const ListToCsvConverter().convert(rows);
  }
}

extension on MLHistory {
  List<List<dynamic>> toCSVList(List<String> headers) {
    List<List<dynamic>> rows = [];
    var seriesId = 0;

    for (final series in series) {
      for (final obs in series.observations) {
        rows.add(obs.toCSVList(upc, seriesId, headers));
      }

      seriesId++;
    }

    return rows;
  }
}

extension on Observation {
  List<dynamic> toCSVList(String upc, int seriesId, List<String> headers) {
    Map<String, dynamic> map = {
      'upc': upc,
      'series_id': seriesId,
      'timestamp': timestamp,
      'amount': amount,
      'weekday': weekday,
      'time_of_year_sin': timeOfYearSin,
      'time_of_year_cos': timeOfYearCos,
      'household_count': householdCount,
    };

    return headers.map((header) => map[header]).toList();
  }
}
