// ignore_for_file: avoid_renaming_method_parameters

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
    final propertyQuery = query.property(ObjectBoxLocation_.name);
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
  void delete(Location item) {
    final query = box
        .query(
            ObjectBoxLocation_.upc.equals(item.upc).and(ObjectBoxLocation_.name.equals(item.name)))
        .build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  void deleteById(String id) {
    if (!id.contains('/')) {
      throw ArgumentError('Invalid location id: $id');
    }

    final upc = id.substring(id.lastIndexOf('/') + 1);
    final location = id.substring(0, id.lastIndexOf('/'));

    if (location.isEmpty || upc.isEmpty) {
      throw ArgumentError('Unable to parse location from $id (location: $location, upc: $upc)');
    }

    final query = box
        .query(ObjectBoxLocation_.upc.equals(upc).and(ObjectBoxLocation_.name.equals(location)))
        .build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  Location? get(String id) {
    if (!id.contains('/')) {
      throw ArgumentError('Invalid location id: $id');
    }

    final upc = id.substring(id.lastIndexOf('/') + 1);
    final location = id.substring(0, id.lastIndexOf('/'));

    if (location.isEmpty || upc.isEmpty) {
      throw ArgumentError('Unable to parse location from $id (location: $location, upc: $upc)');
    }

    final query = box
        .query(ObjectBoxLocation_.upc.equals(upc).and(ObjectBoxLocation_.name.equals(location)))
        .build();
    final result = query.findFirst();
    query.close();

    return result?.toLocation();
  }

  @override
  List<Location> getAll(List<String> ids) {
    final query = box.query(ObjectBoxLocation_.name.oneOf(ids)).build();
    final results = query.find();
    query.close();

    return results.map((objBoxLoc) => objBoxLoc.toLocation()).toList();
  }

  @override
  List<Location> getChanges(DateTime since) {
    final query =
        box.query(ObjectBoxLocation_.updated.greaterThan(since.millisecondsSinceEpoch)).build();
    final results = query.find();
    return results.map((objBoxLoc) => objBoxLoc.toLocation()).toList();
  }

  @override
  List<String> getSubPaths(String location) {
    location = normalizeLocation(location);
    final Set<String> subpaths = {};

    final query = box.query(ObjectBoxLocation_.name.startsWith(location)).build();
    final results = query.find();
    query.close();

    for (final objBoxLoc in results) {
      var normalizedLocName = normalizeLocation(objBoxLoc.name);

      if (normalizedLocName.startsWith(location) && normalizedLocName != location) {
        var remainingPath = normalizedLocName.substring(location.length);
        var nextSlashIndex = remainingPath.indexOf('/');

        if (nextSlashIndex != -1) {
          var subpath = remainingPath.substring(0, nextSlashIndex);

          // Remove trailing slash only if it exists
          if (subpath.endsWith('/')) {
            subpath = subpath.substring(0, subpath.length - 1);
          }

          subpaths.add(subpath);
        } else if (location == '/') {
          subpaths.add(remainingPath);
        }
      }
    }

    var result = subpaths.toList();
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  @override
  List<String> getUpcList(String location) {
    location = normalizeLocation(location);

    final query = box.query(ObjectBoxLocation_.name.equals(location)).build();
    final propertyQuery = query.property(ObjectBoxLocation_.upc);

    List<String> upcs = propertyQuery.find();
    query.close();

    return upcs;
  }

  @override
  int itemCount(String location) {
    final query = box.query(ObjectBoxLocation_.name.equals(location)).build();
    final count = query.count();
    query.close();

    return count;
  }

  @override
  Map<String, Location> map() {
    final allLocations = all();
    final map = {for (final location in allLocations) '${location.name}-${location.upc}': location};

    return map;
  }

  @override
  void put(Location location) {
    final query = box
        .query(ObjectBoxLocation_.upc
            .equals(location.upc)
            .and(ObjectBoxLocation_.name.equals(location.name)))
        .build();
    final exists = query.findFirst();
    query.close();

    final locOb = ObjectBoxLocation.from(location);

    if (exists != null && locOb.objectBoxId != exists.objectBoxId) {
      locOb.objectBoxId = exists.objectBoxId;
      locOb.created = exists.created;
    }

    box.put(locOb);
  }

  @override
  void remove(String location, String upc) {
    final query = box
        .query(ObjectBoxLocation_.name.equals(location).and(ObjectBoxLocation_.upc.equals(upc)))
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
    location = normalizeLocation(location);

    final time = DateTime.now();
    final locObject = Location(name: location, upc: upc, created: time, updated: time);
    put(locObject);
  }
}
