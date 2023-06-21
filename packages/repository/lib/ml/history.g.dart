// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

History _$HistoryFromJson(Map<String, dynamic> json) => History()
  ..upc = json['upc'] as String
  ..series = (json['series'] as List<dynamic>)
      .map((e) => HistorySeries.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      'upc': instance.upc,
      'series': instance.series.map((e) => e.toJson()).toList(),
    };
