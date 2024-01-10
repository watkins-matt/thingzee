import 'package:repository/extension/string.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';

class InventoryCsvRow {
  String upc = '';
  String name = '';
  bool consumable = false;
  int unitCount = 1;
  String category = '';
  String type = '';
  String unitName = 'Package';
  String unitPlural = 'Packages';
  double amount = 0;
  DateTime? lastUpdate;
  bool restock = false;

  void fromRow(List<dynamic> row, Map<String, int> columnIndex) {
    var parsers = {
      'upc': (value) => upc = value.isNotEmpty ? (value as String).normalizeUPC() : upc,
      'name': (value) => name = value.isNotEmpty ? value : name,
      'consumable': (value) => consumable = value.isNotEmpty && value == '1',
      'unit_count': (value) => unitCount = value.isNotEmpty ? int.parse(value) : unitCount,
      'category': (value) => category = value.isNotEmpty ? value : category,
      'type': (value) => type = value.isNotEmpty ? value : type,
      'name_unit': (value) => unitName = value.isNotEmpty ? value : unitName,
      'name_unit_plural': (value) => unitPlural = value.isNotEmpty ? value : unitPlural,
      'quantity': (value) => amount = value.isNotEmpty ? double.parse(value) : amount,
      'update_date': (value) {
        if (value.isNotEmpty) {
          int lastUpdateTimestamp = int.parse(value);

          // If it's 0 assume it's a placeholder so ignore it
          // If it's below zero, the value is invalid
          if (lastUpdateTimestamp > 0) {
            lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
          }
        }
      },
      'restock': (value) => restock = value.isNotEmpty && value == '1',
    };

    // Parse every column that is present
    for (final parser in parsers.entries) {
      if (columnIndex.containsKey(parser.key)) {
        parser.value(row[columnIndex[parser.key]!].toString());
      }
    }
  }

  Inventory toInventory() {
    return Inventory(
      upc: upc,
      amount: amount,
      lastUpdate: lastUpdate,
      restock: restock,
      unitCount: unitCount,
    );
  }

  Item toItem() {
    return Item(
      upc: upc,
      name: name,
      consumable: consumable,
      unitCount: unitCount,
      category: category,
      type: type,
      unitName: unitName,
      unitPlural: unitPlural,
    );
  }
}
