// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_task.dart';

AuditTask _$mergeAuditTask(AuditTask first, AuditTask second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = AuditTask(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    type: newer.type.isNotEmpty ? newer.type : first.type,
    data: newer.data.isNotEmpty ? newer.data : first.data,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    completed: newer.completed,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
