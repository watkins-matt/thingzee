abstract class Preferences {
  bool containsKey(String key);
  int? getInt(String key);
  String? getString(String key);
  Future<bool> remove(String key);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
}
