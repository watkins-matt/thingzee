// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Observation _$ObservationFromJson(Map<String, dynamic> json) => Observation(
      timestamp: (json['timestamp'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      householdCount: json['householdCount'] as int,
    );

Map<String, dynamic> _$ObservationToJson(Observation instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'amount': instance.amount,
      'householdCount': instance.householdCount,
    };
