import 'package:repository/database/audit_task_database.dart';
import 'package:repository/model/audit_task.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/audit_task.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxAuditTaskDatabase extends AuditTaskDatabase
    with ObjectBoxDatabase<AuditTask, ObjectBoxAuditTask> {
  ObjectBoxAuditTaskDatabase(Store store) {
    init(
      store,
      ObjectBoxAuditTask.from,
      ObjectBoxAuditTask_.uid,
      ObjectBoxAuditTask_.updated,
    );
  }
}
