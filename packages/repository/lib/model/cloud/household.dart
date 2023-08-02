import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'household.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class Household {
  final String id; // A unique identifier for the household
  final DateTime timestamp; // When the household was created
  final List<String> userIds; // The ids of the members of the Household
  final List<String> adminIds; // The ids of the admins of the Household
  final List<String> names; // The names of everyone in the household

  const Household({
    required this.id,
    required this.timestamp,
    required this.userIds,
    required this.adminIds,
    required this.names,
  });

  factory Household.fromJson(Map<String, dynamic> json) => _$HouseholdFromJson(json);
  Map<String, dynamic> toJson() => _$HouseholdToJson(this);
}
