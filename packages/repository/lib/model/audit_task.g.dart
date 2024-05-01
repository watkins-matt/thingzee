// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditTask _$AuditTaskFromJson(Map<String, dynamic> json) => AuditTask(
      upc: json['upc'] as String? ?? '',
      type: json['type'] as String? ?? '',
      data: json['data'] as String? ?? '',
      uid: json['uid'] as String?,
      completed: _$JsonConverterFromJson<int, DateTime?>(
          json['completed'], const NullableDateTimeSerializer().fromJson),
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$AuditTaskToJson(AuditTask instance) => <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'upc': instance.upc,
      'type': instance.type,
      'data': instance.data,
      'uid': instance.uid,
      'completed':
          const NullableDateTimeSerializer().toJson(instance.completed),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
