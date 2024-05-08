import os

import pytest

from parser.parsimonious import ParsimoniousParser


@pytest.fixture
def parser():
    path = os.path.join(os.path.dirname(__file__), "..", "grammar", "dart.ppeg")
    return ParsimoniousParser(path)


def test_abstract_class_parsing(parser):
    dart_code = """
    abstract class JsonConvertible<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }
    """

    dart_file = parser.parse(dart_code)
    assert len(dart_file.classes) == 1


def test_abstract_class_parsing_with_comments_and_imports(parser):
    dart_code = """// ignore_for_file: avoid_unused_constructor_parameters

    import 'package:meta/meta.dart';
    import 'package:repository/model/serializer_datetime.dart';

    abstract class JsonConvertible<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }"""

    dart_file = parser.parse(dart_code)
    expected_class_count = 1
    expected_import_count = 2

    assert len(dart_file.classes) == expected_class_count
    assert len(dart_file.imports) == expected_import_count


def test_abstract_class_parsing_with_two_classes(parser):
    dart_code = """// ignore_for_file: avoid_unused_constructor_parameters

    import 'package:meta/meta.dart';
    import 'package:repository/model/serializer_datetime.dart';

    abstract class JsonConvertible<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }

    abstract class JsonConvertible2<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }"""
    dart_file = parser.parse(dart_code)
    expected_class_count = 2

    assert len(dart_file.classes) == expected_class_count


def test_parsing_model_abstract_class(parser):
    dart_code = """// ignore_for_file: avoid_unused_constructor_parameters

    import 'package:meta/meta.dart';
    import 'package:repository/model/serializer_datetime.dart';

    abstract class JsonConvertible<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }

    @immutable
    abstract class Model<T> implements JsonConvertible<T> {
    @DateTimeSerializer()
    final DateTime created;

    @DateTimeSerializer()
    final DateTime updated;

    Model({DateTime? created, DateTime? updated})
        // Initialize 'created' and 'updated' date-times.
        // If 'created' is not provided, it defaults to the value of 'updated' if that was provided,
        // otherwise to the current time. If 'updated' is not provided, it defaults to the value of 'created',
        // ensuring both fields are synchronized and non-null. If both are provided, their values are retained.
        : created = _defaultDateTime(created, updated),
            updated = _defaultDateTime(updated, created);

    bool get isValid => uniqueKey.isNotEmpty;
    String get uniqueKey;

    T copyWith({DateTime? created, DateTime? updated});
    bool equalTo(T other);
    T merge(T other);

    /// This method is a helper method to ensure that
    /// created and updated can be initialized to equivalent values if
    /// one or both are null.
    static DateTime _defaultDateTime(DateTime? primary, DateTime? secondary) {
        return primary ?? secondary ?? DateTime.now();
    }
    }

    /// Annotation for fields that should not be persisted into
    /// generated classes.
    class Transient {
    const Transient();
    }
    """

    dart_file = parser.parse(dart_code)
    expected_class_count = 3

    assert len(dart_file.classes) == expected_class_count


def test_abstract_class_parsing_with_multiple_classes(parser):
    dart_code = """// ignore_for_file: avoid_unused_constructor_parameters

    import 'package:meta/meta.dart';
    import 'package:repository/model/serializer_datetime.dart';

    abstract class JsonConvertible2<T> {
    factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
    Map<String, dynamic> toJson();
    }

    @immutable
    abstract class Model<T> implements JsonConvertible<T> {
    @DateTimeSerializer()
    final DateTime created;

    @DateTimeSerializer()
    final DateTime updated;

    Model({DateTime? created, DateTime? updated})
    // Initialize 'created' and 'updated' date-times.
    // If 'created' is not provided, it defaults to the value of 'updated' if that was provided,
    // otherwise to the current time. If 'updated' is not provided, it defaults to the value of 'created',
    // ensuring both fields are synchronized and non-null. If both are provided, their values are retained.
        : created = _defaultDateTime(created, updated),
            updated = _defaultDateTime(updated, created);

    bool get isValid => uniqueKey.isNotEmpty;
    String get uniqueKey;

    T copyWith({DateTime? created, DateTime? updated});
    bool equalTo(T other);
    T merge(T other);

    /// This method is a helper method to ensure that
    /// created and updated can be initialized to equivalent values if
    /// one or both are null.
    static DateTime _defaultDateTime(DateTime? primary, DateTime? secondary) {
        return primary ?? secondary ?? DateTime.now();
    }
    }
    """

    dart_file = parser.parse(dart_code)
    expected_class_count = 2

    assert len(dart_file.classes) == expected_class_count


def test_parsing_generics(parser):
    dart_code = """import 'package:repository/database/database.dart';
    import 'package:repository/model/abstract/model.dart';

    class ModelProvider<T extends Model<T>> {
    static final Map<Type, ModelProvider> _cache;
    final Map<String, T> _models;
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
        final id = newModel.uniqueKey;
        _models[id] = newModel;
    }
    }
    """

    dart_file = parser.parse(dart_code)
    expected_class_count = 1

    assert len(dart_file.classes) == expected_class_count
