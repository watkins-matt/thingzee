import 'package:repository/database/mock/history_database.dart';
import 'package:repository/database/mock/inventory_database.dart';
import 'package:repository/database/mock/item_database.dart';
import 'package:repository/database/mock/preferences.dart';
import 'package:repository/repository.dart';

class MockRepository extends Repository {
  MockRepository() {
    items = MockItemDatabase();
    inv = MockInventoryDatabase();
    hist = MockHistoryDatabase();
    prefs = MockPreferences();
    securePrefs = MockPreferences();
    ready = true;
  }
}
