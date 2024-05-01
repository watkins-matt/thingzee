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
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'upc': instance.upc,
      'series': instance.series.map((e) => e.toJson()).toList(),
      'updated': const DateTimeSerializer().toJson(instance.updated),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
