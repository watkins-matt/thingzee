import 'package:repository/database/database.dart';
import 'package:repository/model/shopping_item.dart';

abstract class ShoppingListDatabase extends Database<ShoppingItem> {}

class ShoppingListName {
  static const String shopping = 'shopping';
  static const String saved = 'saved';
  static const String cart = 'cart';

  static final Set<String> validIdentifierTypes = {
    ShoppingListName.shopping,
    ShoppingListName.saved,
    ShoppingListName.cart,
  };

  static bool isValid(String identifierType) {
    return validIdentifierTypes.contains(identifierType);
  }
}
