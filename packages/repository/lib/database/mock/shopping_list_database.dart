import 'package:repository/database/mock/mock_database.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';

class MockShoppingListDatabase extends ShoppingListDatabase with MockDatabase<ShoppingItem> {}
