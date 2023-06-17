import 'package:csv/csv.dart';
import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/csv_exporter.dart';

extension on Inventory {
  List<dynamic> toCsvList(Optional<Item> optionalItem, List<String> headers) {
    if (!optionalItem.isPresent) {
      return [];
    }

    Item item = optionalItem.value;

    Map<String, dynamic> map = {
      'upc': upc.normalizeUPC(),
      'name': item.name,
      'quantity': amount,
      'update_date': lastUpdate.isPresent ? lastUpdate.value.millisecondsSinceEpoch : '',
      'consumable': item.consumable ? 1 : 0,
      'unit_count': item.unitCount,
      'category': item.category,
      'type': item.type,
      'name_unit': item.unitName != 'Package' ? item.unitName : '',
      'name_unit_plural': item.unitPlural != 'Packages' ? item.unitPlural : '',
      'restock': restock ? 1 : 0,
    };

    return headers.map((header) => map[header]).toList();
  }
}

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
        'restock'
      ];

  @override
  Future<String> export(Repository r) async {
    List<List<dynamic>> rows = [headers];
    List<Inventory> allInventory = r.inv.all();

    for (final inventory in allInventory) {
      rows.add(inventory.toCsvList(r.items.get(inventory.upc), headers));
    }

    rows.sort((a, b) => a[1].compareTo(b[1]));
    return const ListToCsvConverter().convert(rows);
  }
}
