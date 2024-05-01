// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/audit_task.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxAuditTask extends ObjectBoxModel<AuditTask> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String upc;
  late String type;
  late String data;
  late String uid;
  @Property(type: PropertyType.date)
  late DateTime? completed;
  ObjectBoxAuditTask();
  ObjectBoxAuditTask.from(AuditTask original) {
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
        created: created,
        updated: updated,
        upc: upc,
        type: type,
        data: data,
        uid: uid,
        completed: completed);
  }
}
