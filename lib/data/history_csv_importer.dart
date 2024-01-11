import 'package:csv/csv.dart';
import 'package:log/log.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/history_csv_row.dart';

class HistoryCsvImporter {
  Future<bool> import(String csvString, Repository r) async {
    List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString, shouldParseNumbers: true);
    Map<String, History> upcHistoryMap = {};
    Map<String, List<HistorySeries>> upcSeriesListMap = {};

    if (csvData.isEmpty) {
      return false;
    }

    List<dynamic> headerRow = csvData[0];
    bool headerRowIsValid = headerRow.every((value) => value is String);
    if (!headerRowIsValid) {
      Log.e('Header row is not valid. Import failed.');
      return false;
    }

    Map<String, int> headerIndices = csvData[0].asMap().map((k, v) => MapEntry(v.toString(), k));
    csvData.removeAt(0);

    // Create all the history rows, removing those that are null (invalid)
    List<HistoryCsvRow> allHistoryRows = csvData
        .map((row) => HistoryCsvRow.fromRow(row, headerIndices))
        .whereType<HistoryCsvRow>()
        .toList();

    for (final historyRow in allHistoryRows) {
      // Ensure that the History exists, creating if necessary
      upcHistoryMap.putIfAbsent(historyRow.upc, () => History(upc: historyRow.upc));

      // Initialize series list for each upc
      upcSeriesListMap.putIfAbsent(historyRow.upc, () => []);

      // Check if the seriesId is already in the list for that UPC
      if (upcSeriesListMap[historyRow.upc]!.length <= historyRow.seriesId) {
        upcSeriesListMap[historyRow.upc]!.add(HistorySeries());
      }

      // Add the observation to the correct series
      var series = upcSeriesListMap[historyRow.upc]![historyRow.seriesId];
      series = series.copyWith(
          observations: List.from(series.observations)..add(historyRow.toObservation()));
      upcSeriesListMap[historyRow.upc]![historyRow.seriesId] = series;
    }

    // Add HistorySeries objects to the corresponding History object.
    for (final upc in upcHistoryMap.keys) {
      var seriesList = upcSeriesListMap[upc];
      if (seriesList != null) {
        var history = upcHistoryMap[upc]!.copyWith(series: seriesList);
        r.hist.put(history);
      }
    }

    return true;
  }
}
