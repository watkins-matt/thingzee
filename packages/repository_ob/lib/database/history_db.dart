// ignore_for_file: avoid_renaming_method_parameters

import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model_custom/history_ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxHistoryDatabase extends HistoryDatabase
    with ObjectBoxDatabase<History, ObjectBoxHistory> {
  ObjectBoxHistoryDatabase(Store store) {
    constructDb(store);
  }

  @override
  Condition<ObjectBoxHistory> buildIdCondition(String id) {
    return ObjectBoxHistory_.upc.equals(id);
  }

  @override
  Condition<ObjectBoxHistory> buildIdsCondition(List<String> ids) {
    return ObjectBoxHistory_.upc.oneOf(ids);
  }

  @override
  Condition<ObjectBoxHistory> buildSinceCondition(DateTime since) {
    return ObjectBoxHistory_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxHistory fromModel(History model) => ObjectBoxHistory.from(model);

  @override
  void put(History history) {
    // Remove any invalid values
    history = history.clean(warn: true);

    // Use the put implementation from the mixin
    super.put(history);
  }

  @override
  History toModel(ObjectBoxHistory objectBoxEntity) => objectBoxEntity.toHistory();
}
