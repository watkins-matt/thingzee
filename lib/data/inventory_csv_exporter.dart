import 'package:csv/csv.dart';
import 'package:log/log.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/csv_exporter.dart';
import 'package:util/extension/upc.dart';

class InventoryCsvExporter implements CsvExporter {
  @override
  List<String> get headers => [
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
        'restock',
        'created_date'
      ];

  @override
  Future<String> export(Repository r) async {
    List<List<dynamic>> rows = []; // Headers added at the end
    List<Inventory> allInventory = r.inv.all();

    for (final inventory in allInventory) {
      final inventoryRow = inventory.toCsvList(r.items.get(inventory.upc), headers);

      if (inventoryRow.isNotEmpty) {
        rows.add(inventoryRow);
      } else {
        Log.w('InventoryCsvExporter: Could not find item for inventory UPC ${inventory.upc}');
      }
    }

    // Important: we sort the rows by the second column (name)
    // before we add the headers. This prevents the headers from being
    // sorted themselves
    rows.sort((a, b) => a[1].compareTo(b[1]));

    // Add the headers to the start of the list
    rows.insert(0, headers);

    return const ListToCsvConverter().convert(rows);
  }
}

extension on Inventory {
  List<dynamic> toCsvList(Item? item, List<String> headers) {
    if (item == null) {
      return [];
    }

    Map<String, dynamic> map = {
      'upc': upc.normalizeUPC(),
      'name': item.name,
      'quantity': amount,
      'update_date': updated != null ? updated!.millisecondsSinceEpoch : '',
      'consumable': item.consumable ? 1 : 0,
      'unit_count': item.unitCount,
      'category': item.category,
      'type': item.type,
      'name_unit': item.unitName != 'Package' ? item.unitName : '',
      'name_unit_plural': item.unitPlural != 'Packages' ? item.unitPlural : '',
      'restock': restock ? 1 : 0,
      'created_date': created != null ? created!.millisecondsSinceEpoch : '',
    };

    return headers.map((header) => map[header]).toList();
  }
}
