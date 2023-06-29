import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:repository/ml/history.dart';

class HistoryAdapter extends TypeAdapter<History> {
  @override
  final int typeId = 223;

  @override
  History read(BinaryReader reader) {
    final jsonString = reader.readString();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return History.fromJson(jsonMap);
  }

  @override
  void write(BinaryWriter writer, History obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}
