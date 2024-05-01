import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';

part 'place.g.dart';
part 'place.merge.dart';

String normalizePhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
}

@immutable
@Mergeable()
@JsonSerializable(explicitToJson: true)
class Place extends Model<Place> {
  final String phoneNumber;
  final String name;
  final String city;
  final String state;
  final String zipcode;

  Place({
    String phoneNumber = '',
    this.name = '',
    this.city = '',
    this.state = '',
    this.zipcode = '',
    super.created,
    super.updated,
  }) : phoneNumber = phoneNumber.isNotEmpty ? normalizePhoneNumber(phoneNumber) : '';

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  @override
  String get uniqueKey => phoneNumber;

  @override
  Place copyWith(
      {String? phoneNumber,
      String? name,
      String? city,
      String? state,
      String? zipcode,
      DateTime? created,
      DateTime? updated}) {
    return Place(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      zipcode: zipcode ?? this.zipcode,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Place other) {
    return phoneNumber == other.phoneNumber &&
        name == other.name &&
        city == other.city &&
        state == other.state &&
        zipcode == other.zipcode;
  }

  @override
  Place merge(Place other) => _$mergePlace(this, other);

  @override
  Map<String, dynamic> toJson() => _$PlaceToJson(this);
}
