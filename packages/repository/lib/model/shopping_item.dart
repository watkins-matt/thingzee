import 'package:repository/model/item.dart';

class ShoppingListItem {
  String upc = '';
  bool checked = false;

  Item item = Item();
}

class ShoppingCartItem {
  String upc = '';
  int price = 0;

  Item item = Item();
}
