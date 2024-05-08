// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/audit_task.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxAuditTask extends ObjectBoxModel<AuditTask> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  @Property(type: PropertyType.date)
  late DateTime? completed;
  late String data;
  late String type;
  late String uid;
  late String upc;
  ObjectBoxAuditTask();
  ObjectBoxAuditTask.from(AuditTask original) {
    completed = original.completed;
    created = original.created;
    data = original.data;
    type = original.type;
    uid = original.uid;
    upc = original.upc;
    updated = original.updated;
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
