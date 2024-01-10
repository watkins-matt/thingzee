// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.dart';

HouseholdMember _$mergeHouseholdMember(HouseholdMember first, HouseholdMember second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = HouseholdMember(
    isAdmin: newer.isAdmin,
    email: newer.email.isNotEmpty ? newer.email : first.email,
    householdId: newer.householdId.isNotEmpty ? newer.householdId : first.householdId,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    userId: newer.userId.isNotEmpty ? newer.userId : first.userId,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
