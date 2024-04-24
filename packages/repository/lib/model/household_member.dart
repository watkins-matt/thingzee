import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';
import 'package:util/extension/date_time.dart';

part 'household_member.g.dart';
part 'household_member.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class HouseholdMember extends Model<HouseholdMember> {
  // Whether the user is an admin of the household
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
  final String userId;

  HouseholdMember({
    required this.email,
    required this.householdId,
    required this.name,
    super.created,
    super.updated,
    String? userId = '',
    this.isAdmin = false,
  }) : userId = userId ?? hashEmail(email);

  factory HouseholdMember.fromJson(Map<String, dynamic> json) => _$HouseholdMemberFromJson(json);

  @override
  String get uniqueKey => userId;

  @override
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
  HouseholdMember merge(HouseholdMember other) => _$mergeHouseholdMember(this, other);

  @override
  Map<String, dynamic> toJson() => _$HouseholdMemberToJson(this);
}
