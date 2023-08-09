import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';

part 'household_member.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class HouseholdMember {
  final bool isAdmin; // Whether the user is an admin of the household
  @DateTimeSerializer()
  final DateTime timestamp; // The time the member was added
  final String email; // The email of the user
  final String householdId; // A unique identifier for the household
  final String name; // The name of the user
  final String userId; // A unique identifier for the user

  HouseholdMember({
    required this.email,
    required this.householdId,
    required this.name,
    DateTime? timestamp,
    String? userId,
    this.isAdmin = false,
  })  : timestamp = timestamp ?? DateTime.now(),
        userId = userId ?? hashEmail(email);

  factory HouseholdMember.fromJson(Map<String, dynamic> json) => _$HouseholdMemberFromJson(json);
  Map<String, dynamic> toJson() => _$HouseholdMemberToJson(this);
}
