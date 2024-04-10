import 'package:repository/database/database.dart';
import 'package:repository/model/location.dart';

abstract class LocationDatabase extends Database<Location> {
  List<String> get names;
  List<String> getSubPaths(String location);
  List<String> getUpcList(String location);
  int itemCount(String location);
  void remove(String location, String upc);
  void store(String location, String upc);
}
