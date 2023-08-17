import 'package:repository/model/location.dart';

abstract class LocationDatabase {
  List<String> get all;
  List<Location> getChanges(DateTime since);
  List<Location> getContents(String location);
  List<String> getUpcList(String location);
  int itemCount(String location);
  void remove(String location, String upc);
  void store(String location, String upc);
}
