import 'package:csv/csv.dart';
import 'package:quiver/core.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/history_series.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';

class LegacyCsvImporter {
  static Future<bool> importHistory(String csvString, Repository r) async {
    List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

    assert(csvData[0].length == 8);

    // Remove the header row
    if (csvData.isNotEmpty) {
      csvData.removeAt(0);
    }

    Map<String, History> historyMap = {};
    Map<String, Map<int, HistorySeries>> seriesMap = {};

    for (final row in csvData) {
      final upc = row[0].toString().normalizeUPC();

      if (!historyMap.containsKey(upc)) {
        historyMap[upc] = History()..upc = upc;
        seriesMap[upc] = {};
      }

      // Can't be null since we just added it above
      final currentHistory = historyMap[upc]!;
      int seriesId = row[1] as int;

      HistorySeries historySeries;

      // There isn't an existing series for this seriesId
      if (!seriesMap[upc]!.containsKey(seriesId)) {
        historySeries = HistorySeries();
        seriesMap[upc]![seriesId] = historySeries;
        currentHistory.series.add(historySeries);
      }
      // Use the existing series for this upc and seriesId
      else {
        historySeries = seriesMap[upc]![seriesId]!;
      }

      // Create new Observation from row data
      Observation observation = Observation(
        timestamp: row[2] as double,
        amount: row[3] as double,
        householdCount: row[7] as int,
      );

      // Add the Observation to the corresponding HistorySeries
      historySeries.observations.add(observation);
    }

    // ignore: prefer_foreach
    for (final history in historyMap.values) {
      r.hist.put(history);
    }

    return true;
  }

  static Future<bool> importProductData(String csvString, Repository r) async {
    List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString, eol: '\n');

    // assert(csvData[0].length == 9);

    if (csvData.isNotEmpty) {
      csvData.removeAt(0);
    }

    for (final row in csvData) {
      Item item = Item();

      item.upc = row[0].toString().normalizeUPC();
      item.name = row[1] as String;
      item.consumable = row[2] == 1;
      item.unitCount = row[3] as int;
      item.category = row[4] as String;
      item.type = row[5] as String;
      item.unitName = row[6] as String;
      if (item.unitName.isEmpty) item.unitName = 'Package';

      item.unitPlural = row[7] as String;
      if (item.unitPlural.isEmpty) item.unitPlural = 'Packages';

      if (row.length > 8) {
        item.imageUrl = row[8] as String;
      }

      r.items.put(item);
    }

    return true;
  }

  static Future<bool> importInventoryData(String csvString, Repository r) async {
    List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

    // assert(csvData[0].length == 15);

    if (csvData.isNotEmpty) {
      csvData.removeAt(0);
    }

    for (final row in csvData) {
      Item item = Item();
      item.upc = row[0].toString().normalizeUPC();
      item.name = row[1] as String;
      item.consumable = row[4] == 1;
      item.unitCount = row[5] as int;
      item.category = row[6] as String;
      item.type = row[7] as String;
      item.unitName = row[8] as String;
      if (item.unitName.isEmpty) item.unitName = 'Package';

      item.unitPlural = row[9] as String;
      if (item.unitPlural.isEmpty) item.unitPlural = 'Packages';

      Inventory inventory = Inventory();
      inventory.upc = item.upc;
      inventory.history.upc = item.upc;
      // inventoryInfo.name = row[1] as String;
      inventory.amount = row[2] as double;
      inventory.lastUpdate = Optional.of(DateTime.fromMillisecondsSinceEpoch(row[3] as int));

      // inventoryInfo.dbExpirationDates = jsonDecode(row[10] as String) as List<String>;
      // inventoryInfo.locations = jsonDecode(row[11] as String) as List<String>;
      // inventoryInfo.dbHistory = row[12] as String;
      // inventoryInfo.imageUrl = row[13] as String;
      // item.imageUrl = row[13] as String;

      // if (item.imageUrl.isNotEmpty) {
      //   App.log.d('Found image ${item.name}: URL: ${item.imageUrl}');
      // }

      inventory.restock = row[10] == 1;

      r.items.put(item);
      r.inv.put(inventory);
    }

    return true;
  }
}
