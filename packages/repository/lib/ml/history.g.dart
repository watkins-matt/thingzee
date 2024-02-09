// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

History _$HistoryFromJson(Map<String, dynamic> json) => History(
      upc: json['upc'] as String? ?? '',
      series: (json['series'] as List<dynamic>?)
              ?.map((e) => HistorySeries.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['updated'] as String),
    );

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'upc': instance.upc,
      'series': instance.series.map((e) => e.toJson()).toList(),
      'updated': instance.updated?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
