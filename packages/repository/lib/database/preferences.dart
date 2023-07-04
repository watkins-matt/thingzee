import 'package:shared_preferences/shared_preferences.dart';

abstract class Preferences {
  Future<void> setString(String key, String value);
  String? getString(String key);
  bool containsKey(String key);
  Future<bool> remove(String key);
}

class DefaultSharedPreferences implements Preferences {
  late final SharedPreferences _prefs;

  DefaultSharedPreferences._internal(this._prefs);

  static Future<DefaultSharedPreferences> getInstance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return DefaultSharedPreferences._internal(prefs);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}
