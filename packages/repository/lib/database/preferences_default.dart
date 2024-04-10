import 'package:repository/database/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DefaultSharedPreferences extends Preferences {
  static DefaultSharedPreferences? _instance;
  late final SharedPreferences _prefs;

  DefaultSharedPreferences._internal(this._prefs);

  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<DefaultSharedPreferences> create() async {
    if (_instance == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _instance = DefaultSharedPreferences._internal(prefs);
    }
    return _instance!;
  }
}
