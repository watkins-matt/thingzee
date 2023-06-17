import 'package:csv/csv.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/csv_exporter.dart';

extension on Item {
  List<dynamic> toCSVList(List<String> headers) {
    Map<String, dynamic> map = {
      'upc': upc.normalizeUPC(),
      'name': name,
      'consumable': consumable ? 1 : 0,
      'unit_count': unitCount,
      'category': category,
      'type': type,
      'name_unit': unitName != 'Package' ? unitName : '',
      'name_unit_plural': unitPlural != 'Packages' ? unitPlural : '',
      'image_url': imageUrl,
    };

    return headers.map((header) => map[header]).toList();
  }
}

class ItemCSVExporter implements CSVExporter {
  @override
  List<String> get headers => [
        'upc',
        'name',
        'consumable',
        'unit_count',
        'category',
        'type',
        'name_unit',
        'name_unit_plural',
        'image_url'
      ];

  @override
  Future<String> export(Repository r) async {
    List<List<dynamic>> rows = [headers];
    List<Item> allItems = r.items.all();
    allItems.sort();

    for (final item in allItems) {
      rows.add(item.toCSVList(headers));
    }

    return const ListToCsvConverter().convert(rows);
  }
}
