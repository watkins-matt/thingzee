// ignore_for_file: annotate_overrides
import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:repository/ml/history.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxHistory extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;

  // Serialization occurs though dbHistory
  @Transient()
  History history = History();

  @Unique(onConflict: ConflictStrategy.replace)
  String upc = '';

  ObjectBoxHistory();
  ObjectBoxHistory.from(History original) {
    history = History.fromJson(original.toJson());
    upc = original.upc;
    created = original.created;
    updated = original.updated;
  }

  String get dbHistory {
    return jsonEncode(history.toJson());
  }

  set dbHistory(String value) {
    Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    history = History.fromJson(json).trim();
  }

  History convert() {
    return history;
  }
}
