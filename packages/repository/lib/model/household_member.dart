import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';

part 'household_member.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class HouseholdMember extends Model<HouseholdMember> {
  // Whether the user is an admin of the household
  @JsonKey(defaultValue: false)
  final bool isAdmin;

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
    super.created,
    super.updated,
    String? userId,
    this.isAdmin = false,
  }) : userId = userId ?? hashEmail(email);

  factory HouseholdMember.fromJson(Map<String, dynamic> json) => _$HouseholdMemberFromJson(json);

  @override
  String get id => userId;

  HouseholdMember copyWith({
    bool? isAdmin,
    String? email,
    String? householdId,
    String? name,
    String? userId,
    DateTime? created,
    DateTime? updated,
  }) {
    return HouseholdMember(
      isAdmin: isAdmin ?? this.isAdmin,
      email: email ?? this.email,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(HouseholdMember other) {
    return email == other.email &&
        householdId == other.householdId &&
        name == other.name &&
        userId == other.userId &&
        isAdmin == other.isAdmin;
  }

  @override
  HouseholdMember merge(HouseholdMember other) {
    if (userId != other.userId) {
      throw Exception('Cannot merge HouseholdMembers with different userIds.');
    }

    // Determine which HouseholdMember is newer based on the 'created' date.
    final newerMember = other.created!.isAfter(created!) ? other : this;

    // Merge the fields, preferring the values from the newer member.
    return HouseholdMember(
        email: newerMember.email.isNotEmpty ? newerMember.email : email,
        householdId: newerMember.householdId.isNotEmpty ? newerMember.householdId : householdId,
        name: newerMember.name.isNotEmpty ? newerMember.name : name,
        created: newerMember.created,
        updated: DateTime.now(), // Update the 'updated' field to now
        userId: userId,
        isAdmin: newerMember.isAdmin);
  }

  @override
  Map<String, dynamic> toJson() => _$HouseholdMemberToJson(this);
}
