import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/item_csv_row.dart';

class ItemCsvImporter {
  Future<bool> import(String csvString, Repository r) async {
    List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString, shouldParseNumbers: true);

    if (csvData.isEmpty) {
      return false;
    }

    List<dynamic> headerRow = csvData[0];
    bool headerRowIsValid = headerRow.every((value) => value is String);
    if (!headerRowIsValid) {
      debugPrint('Header row is not valid. Import failed.');
      return false;
    }

    Map<String, int> headerIndices = csvData[0].asMap().map((k, v) => MapEntry(v.toString(), k));
    csvData.removeAt(0);

    for (final row in csvData) {
      ItemCsvRow itemRow = ItemCsvRow();
      itemRow.fromRow(row, headerIndices);
      r.items.put(itemRow.toItem());
    }

    return true;
  }
}
