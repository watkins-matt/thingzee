import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:repository/ml/history.dart';

@Entity()
class ObjectBoxHistory {
  History history = History();

  @Unique()
  String upc = '';

  @Id()
  int id = 0;

  ObjectBoxHistory();
  ObjectBoxHistory.from(History original) {
    history = original;
    upc = original.upc;
  }
  History toHistory() {
    return history;
  }

  String get dbHistory {
    return jsonEncode(history.toJson());
  }

  set dbHistory(String value) {
    Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    history = History.fromJson(json).trim();
  }
}
