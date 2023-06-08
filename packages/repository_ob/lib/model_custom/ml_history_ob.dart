import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:repository/ml/ml_history.dart';

@Entity()
class ObjectBoxMLHistory {
  MLHistory history = MLHistory();

  @Unique()
  String upc = '';

  @Id()
  int id = 0;

  ObjectBoxMLHistory();
  ObjectBoxMLHistory.from(MLHistory original) {
    history = original;
    upc = original.upc;
  }
  MLHistory toMLHistory() {
    return history;
  }

  String get dbHistory {
    return jsonEncode(history.toJson());
  }

  set dbHistory(String value) {
    Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    history = MLHistory.fromJson(json).trim();
  }
}
