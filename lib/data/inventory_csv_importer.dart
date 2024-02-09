import 'package:csv/csv.dart';
import 'package:log/log.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/inventory_csv_row.dart';

class InventoryCsvImporter {
  Future<bool> import(String csvString, Repository r) async {
    List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString, shouldParseNumbers: true);

    if (csvData.isEmpty) {
      return false;
    }

    // Validate the header row
    List<dynamic> headerRow = csvData[0];
    bool headerRowIsValid = headerRow.every((value) => value is String);
    if (!headerRowIsValid) {
      Log.e('Header row is not valid. Import failed.');
      return false;
    }

    Map<String, int> headerIndices = csvData[0].asMap().map((k, v) => MapEntry(v.toString(), k));
    csvData.removeAt(0);

    for (final row in csvData) {
      InventoryCsvRow inventoryRow = InventoryCsvRow();
      inventoryRow.fromRow(row, headerIndices);

      var inv = inventoryRow.toInventory();
      r.inv.put(inv);
    }

    return true;
  }
}
