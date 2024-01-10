import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/model/household_member.ob.dart';
import 'package:repository_ob/objectbox.g.dart';
import 'package:uuid/uuid.dart';

class ObjectBoxHouseholdDatabase extends HouseholdDatabase {
  late Box<ObjectBoxHouseholdMember> box;
  final Preferences prefs;
  String? _householdId;
  DateTime? _created;

  ObjectBoxHouseholdDatabase(Store store, this.prefs) {
    box = store.box<ObjectBoxHouseholdMember>();

    // Check if household_id and household_created exist in preferences
    if (!prefs.containsKey('household_id') || !prefs.containsKey('household_created')) {
      _createNewHousehold();
    } else {
      _loadHousehold();
    }
  }

  @override
  List<HouseholdMember> get admins {
    final query = box.query(ObjectBoxHouseholdMember_.isAdmin.equals(true)).build();
    final results = query.find();
    query.close();

    return results.map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  DateTime get created => _created!;

  @override
  String get id => _householdId!;

  @override
  List<HouseholdMember> get members {
    final all = box.getAll();
    return all.map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  List<HouseholdMember> all() {
    return box.getAll().map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  void delete(HouseholdMember member) {
    final query = box.query(ObjectBoxHouseholdMember_.userId.equals(member.userId)).build();
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
  void deleteById(String userId) {
    final query = box.query(ObjectBoxHouseholdMember_.userId.equals(userId)).build();
    final member = query.findFirst();
    query.close();

    if (member != null) {
      box.remove(member.objectBoxId);
    }
  }

  @override
  HouseholdMember? get(String userId) {
    final query = box.query(ObjectBoxHouseholdMember_.userId.equals(userId)).build();
    final member = query.findFirst();
    query.close();

    return member?.toHouseholdMember();
  }

  @override
  List<HouseholdMember> getAll(List<String> userIds) {
    final query = box.query(ObjectBoxHouseholdMember_.userId.oneOf(userIds)).build();
    final members = query.find();
    query.close();

    return members.map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  List<HouseholdMember> getChanges(DateTime since) {
    final query = box
        .query(ObjectBoxHouseholdMember_.updated.greaterThan(since.millisecondsSinceEpoch))
        .build();
    final results = query.find();
    return results.map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  void leave() {
    box.removeAll();
    _createNewHousehold();
  }

  @override
  Map<String, HouseholdMember> map() {
    final all = box.getAll();
    return {
      for (final objBoxMember in all)
        objBoxMember.objectBoxId.toString(): objBoxMember.toHouseholdMember()
    };
  }

  @override
  void put(HouseholdMember member) {
    final identifierOb = ObjectBoxHouseholdMember.from(member);

    final query = box.query(ObjectBoxHouseholdMember_.userId.equals(member.userId)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && identifierOb.objectBoxId != exists.objectBoxId) {
      identifierOb.objectBoxId = exists.objectBoxId;
    }

    box.put(identifierOb);
  }

  void _createNewHousehold() {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    prefs.setString('household_id', _householdId!);
    prefs.setInt('household_created', created.millisecondsSinceEpoch);
  }

  void _loadHousehold() {
    _householdId = prefs.getString('household_id')!;
    _created = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('household_created')!);
  }
}
