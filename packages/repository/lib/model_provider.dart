import 'package:repository/database/database.dart';
import 'package:repository/model/abstract/model.dart';

class ModelProvider<T extends Model<T>> {
  static final Map<Type, ModelProvider> _cache = {};
  final Map<String, T> _models = {};
  Database<T>? _db;

  factory ModelProvider() {
    if (!_cache.containsKey(T)) {
      _cache[T] = ModelProvider<T>._internal();
    }

    return _cache[T] as ModelProvider<T>;
  }

  ModelProvider._internal();

  Database<T> get db {
    if (_db == null) {
      throw Exception('$T Provider not initialized with a Database instance.');
    }

    return _db!;
  }

  T get(String id, T defaultValue) {
    return _models.putIfAbsent(id, () => db.get(id) ?? defaultValue);
  }

  void init(Database<T> database) {
    _db = database;

    _db!.addHook((T? model, String type) async {
      if (type == DatabaseHookType.put) {
        updateModel(model!);
      }
    });
  }

  void updateModel(T newModel) {
    final id = newModel.id;
    _models[id] = newModel;
  }
}
