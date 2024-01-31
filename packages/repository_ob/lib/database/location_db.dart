import 'package:repository/database/location_database.dart';
import 'package:repository/model/location.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/location.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxLocationDatabase extends LocationDatabase
    with ObjectBoxDatabase<Location, ObjectBoxLocation> {
  ObjectBoxLocationDatabase(Store store) {
    constructDb(store);
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
  Condition<ObjectBoxLocation> buildIdCondition(String id) {
    if (!id.contains('/')) {
      throw ArgumentError('Invalid location id: $id');
    }

    final upc = id.substring(id.lastIndexOf('/') + 1);
    final location = id.substring(0, id.lastIndexOf('/'));

    if (location.isEmpty || upc.isEmpty) {
      throw ArgumentError('Unable to parse location from $id');
    }

    return ObjectBoxLocation_.upc.equals(upc).and(ObjectBoxLocation_.name.equals(location));
  }

  @override
  Condition<ObjectBoxLocation> buildIdsCondition(List<String> ids) {
    return ObjectBoxLocation_.name.oneOf(ids);
  }

  @override
  Condition<ObjectBoxLocation> buildSinceCondition(DateTime since) {
    return ObjectBoxLocation_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxLocation fromModel(Location model) => ObjectBoxLocation.from(model);

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

  @override
  Location toModel(ObjectBoxLocation objectBoxEntity) => objectBoxEntity.toLocation();
}
