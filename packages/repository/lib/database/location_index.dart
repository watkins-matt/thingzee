import 'package:repository/model/item.dart';

abstract class LocationIndex {
  List<String> get all;
  List<String> contents(String location);
  int itemCount(String location);
  void refresh();
  void removeProduct(Item product);
  void update(Item product);
}
