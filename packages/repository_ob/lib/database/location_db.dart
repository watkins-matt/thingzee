import 'package:repository/database/location_database.dart';
import 'package:repository/model/location.dart';
import 'package:repository_ob/model/location.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxLocationDatabase extends LocationDatabase {
  late Box<ObjectBoxLocation> box;

  ObjectBoxLocationDatabase(Store store) {
    box = store.box<ObjectBoxLocation>();
  }

  @override
  List<String> get names {
    final query = box.query().build();
    final propertyQuery = query.property(ObjectBoxLocation_.location);
    propertyQuery.distinct = true;

    List<String> locations = propertyQuery.find();
    query.close();

    return locations;
  }

  @override
  List<Location> all() {
    final all = box.getAll();
    return all.map((objBoxLoc) => objBoxLoc.toLocation()).toList();
  }

  @override
  List<Location> getChanges(DateTime since) {
    final query =
        box.query(ObjectBoxLocation_.updated.greaterThan(since.millisecondsSinceEpoch)).build();
    final results = query.find();
    return results.map((objBoxLoc) => objBoxLoc.toLocation()).toList();
  }

  @override
  List<Location> getContents(String location) {
    final query = box.query(ObjectBoxLocation_.location.equals(location)).build();
    final results = query.find();

    List<Location> locations = results.map((objBoxLoc) => objBoxLoc.toLocation()).toList();
    query.close();

    return locations;
  }

  @override
  List<String> getUpcList(String location) {
    final query = box.query(ObjectBoxLocation_.location.equals(location)).build();
    final propertyQuery = query.property(ObjectBoxLocation_.upc);

    List<String> upcs = propertyQuery.find();
    query.close();

    return upcs;
  }

  @override
  int itemCount(String location) {
    final query = box.query(ObjectBoxLocation_.location.equals(location)).build();
    final count = query.count();
    query.close();

    return count;
  }

  @override
  Map<String, Location> map() {
    final allLocations = all();
    final map = {
      for (final location in allLocations) '${location.location}-${location.upc}': location
    };

    return map;
  }

  @override
  void remove(String location, String upc) {
    final query = box
        .query(ObjectBoxLocation_.location.equals(location).and(ObjectBoxLocation_.upc.equals(upc)))
        .build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  void store(String location, String upc) {
    assert(upc.isNotEmpty && location.isNotEmpty);
    final time = DateTime.now();
    final locOb = ObjectBoxLocation.from(
        Location(location: location, upc: upc, created: time, updated: time));

    final query = box
        .query(ObjectBoxLocation_.upc.equals(upc).and(ObjectBoxLocation_.location.equals(location)))
        .build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && locOb.objectBoxId != exists.objectBoxId) {
      locOb.objectBoxId = exists.objectBoxId;
      locOb.created = exists.created;
    }

    box.put(locOb);
  }
}
