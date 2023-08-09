import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/model/household_member.ob.dart';
import 'package:repository_ob/objectbox.g.dart';
import 'package:uuid/uuid.dart';

class ObjectBoxHouseholdDatabase extends HouseholdDatabase {
  late Box<ObjectBoxHouseholdMember> box;
  final Preferences prefs;
  late final String _householdId;
  late final DateTime _created;

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
  DateTime get created => _created;

  @override
  String get id => _householdId;

  @override
  List<HouseholdMember> get members {
    final all = box.getAll();
    return all.map((objBoxMember) => objBoxMember.toHouseholdMember()).toList();
  }

  @override
  void addMember(String name, String email, {String? id, bool isAdmin = false}) {
    if (id != null && members.any((element) => element.userId == id)) {
      throw Exception('User already exists in household.');
    }

    final householdMember = ObjectBoxHouseholdMember.from(
      HouseholdMember(
        email: email,
        householdId: _householdId,
        name: name,
        isAdmin: isAdmin,
        userId: id ?? const Uuid().v4(),
      ),
    );
    box.put(householdMember);
  }

  @override
  void leave() {
    box.removeAll();
    _createNewHousehold();
  }

  void _createNewHousehold() {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    prefs.setString('household_id', _householdId);
    prefs.setInt('household_created', created.millisecondsSinceEpoch);
  }

  void _loadHousehold() {
    _householdId = prefs.getString('household_id')!;
    _created = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('household_created')!);
  }
}
