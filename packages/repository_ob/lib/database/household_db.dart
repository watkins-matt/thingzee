import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/household_member.ob.dart';
import 'package:repository_ob/objectbox.g.dart';
import 'package:uuid/uuid.dart';

class ObjectBoxHouseholdDatabase extends HouseholdDatabase
    with ObjectBoxDatabase<HouseholdMember, ObjectBoxHouseholdMember> {
  final Preferences prefs;
  String? _householdId;
  DateTime? _created;

  ObjectBoxHouseholdDatabase(Store store, this.prefs) : super() {
    init(store, ObjectBoxHouseholdMember.from, ObjectBoxHouseholdMember_.userId,
        ObjectBoxHouseholdMember_.updated);

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
    return results.map(convert).toList();
  }

  @override
  DateTime get created => _created!;

  @override
  String get id => _householdId!;

  @override
  void leave() {
    box.removeAll();
    _createNewHousehold();
  }

  void _createNewHousehold() {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    prefs.setString('household_id', _householdId!);
    prefs.setInt('household_created', _created!.millisecondsSinceEpoch);
  }

  void _loadHousehold() {
    _householdId = prefs.getString('household_id')!;
    _created = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('household_created')!);
  }
}
