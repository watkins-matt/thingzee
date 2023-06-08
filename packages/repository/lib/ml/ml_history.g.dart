// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ml_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MLHistory _$MLHistoryFromJson(Map<String, dynamic> json) => MLHistory()
  ..upc = json['upc'] as String
  ..series = (json['series'] as List<dynamic>)
      .map((e) => HistorySeries.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$MLHistoryToJson(MLHistory instance) => <String, dynamic>{
      'upc': instance.upc,
      'series': instance.series.map((e) => e.toJson()).toList(),
    };
