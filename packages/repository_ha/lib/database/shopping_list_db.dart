import 'package:log/log.dart';
import 'package:repository/database/mock/mock_database.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ha/home_assistant_api.dart';

class HomeAssistantShoppingListDatabase extends ShoppingListDatabase
    with MockDatabase<ShoppingItem> {
  HomeAssistantApi api;
  String entityId;

  HomeAssistantShoppingListDatabase(this.api, this.entityId);

  Future<void> fetch() async {
    Log.i('Fetching shopping list from Home Assistant...');

    // Clear the database before fetching new data
    deleteAll();

    // Get all the items from Home Assistant
    final items = await api.fetchTodoData(entityId);

    // Put all the items into the in-memory database
    for (final item in items) {
      db[item.uniqueKey] = item;
    }

    Log.i('Fetched ${items.length} items from Home Assistant.');
  }
}
