import 'package:csv/csv.dart';
import 'package:quiver/core.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/ml/observation.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';

class LegacyCsvExporter {
  static Future<String> exportHistory(Repository r) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'upc',
      'series_id',
      'timestamp',
      'amount',
      'weekday',
      'time_of_year_sin',
      'time_of_year_cos',
      'household_count'
    ]);

    List<History> allHistory = r.hist.all();

    for (final history in allHistory) {
      rows.addAll(convertHistoryToList(history));
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> exportProductData(Repository r) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'upc',
      'name',
      'consumable',
      'unit_count',
      'category',
      'type',
      'name_unit',
      'name_unit_plural',
      'image_url'
    ]);

    List<Item> allItems = r.items.all();
    allItems.sort();

    for (final item in allItems) {
      rows.add(convertItemToList(item));
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> exportInventoryData(Repository r) async {
    List<List<dynamic>> rows = [];

    List<Inventory> allInventory = r.inv.all();

    for (final inventory in allInventory) {
      rows.add(convertInventoryToList(inventory, r.items.get(inventory.upc)));
    }

    // Sort all the rows by the name column
    rows.sort((a, b) => a[1].compareTo(b[1]));

    // Prepend the header row
    rows.insert(0, [
      'upc',
      'name',
      'quantity',
      'update_date',
      'consumable',
      'unit_count',
      'category',
      'type',
      'name_unit',
      'name_unit_plural',
      'restock'
    ]);

    return const ListToCsvConverter().convert(rows);
  }

  static List<List<dynamic>> convertHistoryToList(History history) {
    List<List<dynamic>> rows = [];
    var seriesId = 0;

    for (final series in history.series) {
      for (final obs in series.observations) {
        final row = observationToList(history, obs, seriesId);
        rows.add(row);
      }

      seriesId++;
    }

    return rows;
  }

  static List<dynamic> observationToList(History history, Observation obs, int seriesId) {
    return [
      history.upc,
      seriesId,
      obs.timestamp,
      obs.amount,
      obs.weekday,
      obs.timeOfYearSin,
      obs.timeOfYearCos,
      obs.householdCount
    ];
  }

  static List<dynamic> convertItemToList(Item item) {
    return [
      item.upc.normalizeUPC(),
      item.name,
      item.consumable ? 1 : 0,
      item.unitCount,
      item.category,
      item.type,
      item.unitName != 'Package' ? item.unitName : '',
      item.unitPlural != 'Packages' ? item.unitPlural : '',
      item.imageUrl
    ];
  }

  static List<dynamic> convertInventoryToList(Inventory inventory, Optional<Item> optionalItem) {
    if (!optionalItem.isPresent) {
      // This should not happen if the database is in a consistent state
      return [];
    }

    Item item = optionalItem.value;

    return [
      inventory.upc.normalizeUPC(),
      item.name,
      inventory.amount,
      inventory.lastUpdate.or(DateTime(0)).millisecondsSinceEpoch,
      item.consumable ? 1 : 0,
      item.unitCount,
      item.category,
      item.type,
      item.unitName != 'Package' ? item.unitName : '',
      item.unitPlural != 'Packages' ? item.unitPlural : '',
      inventory.restock ? 1 : 0
    ];
  }
}
