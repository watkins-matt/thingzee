// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/audit_task.dart';

part 'audit_task.hive.g.dart';

@HiveType(typeId: 0)
class HiveAuditTask extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late String type;
  @HiveField(4)
  late String data;
  @HiveField(5)
  late String uid;
  @HiveField(6)
  late DateTime? completed;
  HiveAuditTask();
  HiveAuditTask.from(AuditTask original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    type = original.type;
    data = original.data;
    uid = original.uid;
    completed = original.completed;
  }
  AuditTask convert() {
    return AuditTask(
        completed: completed,
        created: created,
        data: data,
        type: type,
        uid: uid,
        upc: upc,
        updated: updated);
  }
}
