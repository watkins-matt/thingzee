import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';

part 'household_member.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class HouseholdMember {
  // Whether the user is an admin of the household
  @JsonKey(defaultValue: false)
  final bool isAdmin;

  // The time the member was created
  @DateTimeSerializer()
  final DateTime timestamp;

  // The email of the user
  @JsonKey(defaultValue: '')
  final String email;

  // A unique identifier for the household
  @JsonKey(defaultValue: '')
  final String householdId;

  // The name of the user
  @JsonKey(defaultValue: '')
  final String name;

  // A unique identifier for the user
  @JsonKey(defaultValue: '')
  final String userId;

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
