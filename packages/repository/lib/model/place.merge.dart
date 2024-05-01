// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

Place _$mergePlace(Place first, Place second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Place(
    phoneNumber: newer.phoneNumber.isNotEmpty ? newer.phoneNumber : first.phoneNumber,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    city: newer.city.isNotEmpty ? newer.city : first.city,
    state: newer.state.isNotEmpty ? newer.state : first.state,
    zipcode: newer.zipcode.isNotEmpty ? newer.zipcode : first.zipcode,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
