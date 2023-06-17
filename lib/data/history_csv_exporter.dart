import 'package:csv/csv.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/csv_exporter.dart';

class HistoryCsvExporter implements CsvExporter {
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

    List<History> allHistory = r.hist.all();

    for (final history in allHistory) {
      rows.addAll(history.toCsvList(headers));
    }

    return const ListToCsvConverter().convert(rows);
  }
}

extension on History {
  List<List<dynamic>> toCsvList(List<String> headers) {
    List<List<dynamic>> rows = [];
    var seriesId = 0;

    for (final series in series) {
      for (final obs in series.observations) {
        rows.add(obs.toCsvList(upc, seriesId, headers));
      }

      seriesId++;
    }

    return rows;
  }
}

extension on Observation {
  List<dynamic> toCsvList(String upc, int seriesId, List<String> headers) {
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
