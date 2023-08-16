import 'package:repository/model/location.dart';

abstract class LocationDatabase {
  List<String> get all;
  List<String> contents(String location);
  void delete(Location location);
  int itemCount(String location);
  void store(Location location);
}
