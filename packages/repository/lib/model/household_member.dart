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

  HouseholdMember copyWith({
    bool? isAdmin,
    DateTime? timestamp,
    String? email,
    String? householdId,
    String? name,
    String? userId,
  }) {
    return HouseholdMember(
      isAdmin: isAdmin ?? this.isAdmin,
      timestamp: timestamp ?? this.timestamp,
      email: email ?? this.email,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      userId: userId ?? this.userId,
    );
  }

  HouseholdMember merge(HouseholdMember other) => _$merge(this, other);

  Map<String, dynamic> toJson() => _$HouseholdMemberToJson(this);
  HouseholdMember _$merge(HouseholdMember first, HouseholdMember second) {
    // Check if the userIds match. If not, throw an exception.
    if (first.userId != second.userId) {
      throw Exception('Cannot merge HouseholdMembers with different userIds.');
    }

    // Determine which HouseholdMember is newer based on the timestamp.
    final newerMember = second.timestamp.isAfter(first.timestamp) ? second : first;

    // Merge the fields, preferring the values from the newer member.
    return HouseholdMember(
        email: newerMember.email.isNotEmpty ? newerMember.email : first.email,
        householdId:
            newerMember.householdId.isNotEmpty ? newerMember.householdId : first.householdId,
        name: newerMember.name.isNotEmpty ? newerMember.name : first.name,
        timestamp: newerMember.timestamp,
        userId: first.userId,
        isAdmin: newerMember.isAdmin);
  }
}
