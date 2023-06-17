import 'package:repository/extension/string.dart';
import 'package:repository/model/item.dart';

class ItemCsvRow {
  String upc = '';
  String name = '';
  bool consumable = false;
  int unitCount = 1;
  String category = '';
  String type = '';
  String unitName = '';
  String unitPlural = '';
  String imageUrl = '';

  void fromRow(List<dynamic> row, Map<String, int> columnIndex) {
    final parsers = {
      'upc': (value) => upc = value.isNotEmpty ? (value as String).normalizeUPC() : upc,
      'name': (value) => name = value.isNotEmpty ? value : name,
      'consumable': (value) => consumable = value.isNotEmpty && value == '1',
      'unit_count': (value) => unitCount = value.isNotEmpty ? int.parse(value) : unitCount,
      'category': (value) => category = value.isNotEmpty ? value : category,
      'type': (value) => type = value.isNotEmpty ? value : type,
      'name_unit': (value) => unitName = value.isNotEmpty ? value : unitName,
      'name_unit_plural': (value) => unitPlural = value.isNotEmpty ? value : unitPlural,
      'image_url': (value) => imageUrl = value.isNotEmpty ? value : imageUrl,
    };

    // Parse every column that is present
    for (final parser in parsers.entries) {
      if (columnIndex.containsKey(parser.key)) {
        parser.value(row[columnIndex[parser.key]!].toString());
      }
    }
  }

  Item toItem() {
    return Item()
      ..upc = upc
      ..name = name
      ..consumable = consumable
      ..unitCount = unitCount
      ..category = category
      ..type = type
      ..unitName = unitName
      ..unitPlural = unitPlural
      ..imageUrl = imageUrl;
  }
}
