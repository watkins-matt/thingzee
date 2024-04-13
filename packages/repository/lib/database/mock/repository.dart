import 'package:repository/database/mock/history_database.dart';
import 'package:repository/database/mock/inventory_database.dart';
import 'package:repository/database/mock/item_database.dart';
import 'package:repository/database/mock/preferences.dart';
import 'package:repository/database/mock/shopping_list_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model_provider.dart';
import 'package:repository/repository.dart';

class MockRepository extends Repository {
  MockRepository() {
    items = MockItemDatabase();
    inv = MockInventoryDatabase();
    hist = MockHistoryDatabase();
    prefs = MockPreferences();
    securePrefs = MockPreferences();
    shopping = MockShoppingListDatabase();
    ready = true;
  }

  void installMockModelProvider() {
    ModelProvider<History>().init(hist);
    ModelProvider<Item>().init(items);
    ModelProvider<Inventory>().init(inv);
  }
}
