import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:repository/database/preferences.dart';

class SecurePreferences extends Preferences {
  static SecurePreferences? _instance;
  final FlutterSecureStorage _storage;

  final Map<String, String> _cache = {};
  SecurePreferences._internal(this._storage);

  @override
  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  @override
  int? getInt(String key) {
    return int.tryParse(_cache[key] ?? '');
  }

  @override
  String? getString(String key) {
    return _cache[key];
  }

  @override
  Future<bool> remove(String key) async {
    await _storage.delete(key: key);
    _cache.remove(key);
    return true;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
    _cache[key] = value.toString();
  }

  @override
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
    _cache[key] = value;
  }

  Future<void> _populateCache() async {
    _cache.addAll(await _storage.readAll());
  }

  static Future<SecurePreferences> create() async {
    if (_instance == null) {
      FlutterSecureStorage storage = const FlutterSecureStorage();
      SecurePreferences instance = SecurePreferences._internal(storage);
      await instance._populateCache();
      _instance = instance;
    }
    return _instance!;
  }
}
