import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';
import 'package:uuid/uuid.dart';

part 'audit_task.g.dart';
part 'audit_task.merge.dart';

@immutable
@Mergeable()
@JsonSerializable(explicitToJson: true)
class AuditTask extends Model<AuditTask> {
  final String upc;
  final String type;
  final String data;
  final String uid;

  @NullableDateTimeSerializer()
  @JsonKey(defaultValue: null)
  final DateTime? completed;

  AuditTask({
    this.upc = '',
    this.type = '',
    this.data = '',
    String? uid,
    this.completed,
    super.created,
    super.updated,
  }) : uid = uid != null && uid.isNotEmpty ? uid : const Uuid().v4();

  DateTime? get generated => created;

  bool get isComplete => completed != null;

  @override
  String get uniqueKey => uid;

  @override
  AuditTask copyWith(
      {String? upc,
      String? type,
      String? data,
      String? uid,
      DateTime? completed,
      DateTime? created,
      DateTime? updated}) {
    return AuditTask(
      upc: upc ?? this.upc,
      type: type ?? this.type,
      data: data ?? this.data,
      uid: uid ?? this.uid,
      completed: completed ?? this.completed,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(AuditTask other) {
    return upc == other.upc &&
        type == other.type &&
        data == other.data &&
        uid == other.uid &&
        completed == other.completed &&
        created == other.created &&
        updated == other.updated;
  }

  @override
  AuditTask merge(AuditTask other) => _$mergeAuditTask(this, other);

  @override
  Map<String, dynamic> toJson() => _$AuditTaskToJson(this);
}
