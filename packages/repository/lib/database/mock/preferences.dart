import 'package:repository/database/preferences.dart';

class MockPreferences extends Preferences {
  final Map<String, String> _prefs = {};

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  int? getInt(String key) {
    return int.tryParse(_prefs[key] ?? '');
  }

  @override
  String? getString(String key) => _prefs[key];

  @override
  Future<bool> remove(String key) async {
    _prefs.remove(key);
    return true;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
    _prefs[key] = value.toString();
  }

  @override
  Future<void> setString(String key, String value) async {
    _prefs[key] = value;
  }
}
