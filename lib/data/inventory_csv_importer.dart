import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';
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
      debugPrint('Header row is not valid. Import failed.');
      return false;
    }

    Map<String, int> headerIndices = csvData[0].asMap().map((k, v) => MapEntry(v.toString(), k));
    csvData.removeAt(0);

    for (final row in csvData) {
      InventoryCsvRow inventoryRow = InventoryCsvRow();
      inventoryRow.fromRow(row, headerIndices);

      // Pull the history before updating the inventory
      var inv = inventoryRow.toInventory();
      final historyResult = r.hist.get(inv.upc);
      if (historyResult.isNotEmpty) {
        inv.history = historyResult.value;
      }

      r.items.put(inventoryRow.toItem());
      r.inv.put(inv);
    }

    return true;
  }
}
