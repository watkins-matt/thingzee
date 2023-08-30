import 'package:repository/model/location.dart';

abstract class LocationDatabase {
  List<String> get names;
  List<Location> all();
  List<Location> getChanges(DateTime since);
  List<String> getSubPaths(String location);
  List<String> getUpcList(String location);
  int itemCount(String location);
  Map<String, Location> map();
  void remove(String location, String upc);
  void store(String location, String upc);
}
