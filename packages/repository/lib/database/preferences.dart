import 'package:shared_preferences/shared_preferences.dart';

class DefaultSharedPreferences implements Preferences {
  late final SharedPreferences _prefs;

  DefaultSharedPreferences._internal(this._prefs);

  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
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
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<DefaultSharedPreferences> create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return DefaultSharedPreferences._internal(prefs);
  }
}

abstract class Preferences {
  bool containsKey(String key);
  String? getString(String key);
  Future<bool> remove(String key);
  Future<void> setString(String key, String value);
}
