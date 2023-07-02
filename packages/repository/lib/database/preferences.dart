import 'package:shared_preferences/shared_preferences.dart';

abstract class Preferences {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<bool> containsKey(String key);
}

class DefaultSharedPreferences implements Preferences {
  late SharedPreferences _prefs;

  DefaultSharedPreferences() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
}
