// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

History _$HistoryFromJson(Map<String, dynamic> json) => History()
  ..series = (json['series'] as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>).map(
            (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
          ))
      .toList();

Map<String, dynamic> _$HistoryToJson(History instance) => <String, dynamic>{
      'series': instance.series
          .map((e) => e.map((k, e) => MapEntry(k.toString(), e)))
          .toList(),
    };
