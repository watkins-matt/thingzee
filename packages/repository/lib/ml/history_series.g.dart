// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistorySeries _$HistorySeriesFromJson(Map<String, dynamic> json) =>
    HistorySeries()
      ..observations = (json['observations'] as List<dynamic>)
          .map((e) => Observation.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$HistorySeriesToJson(HistorySeries instance) =>
    <String, dynamic>{
      'observations': instance.observations.map((e) => e.toJson()).toList(),
    };
