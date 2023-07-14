abstract class Preferences {
  bool containsKey(String key);
  String? getString(String key);
  Future<bool> remove(String key);
  Future<void> setString(String key, String value);
}
