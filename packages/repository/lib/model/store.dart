import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:util/extension/date_time.dart';

part 'store.g.dart';
part 'store.merge.dart';

String normalizePhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
}

@immutable
@Mergeable()
@JsonSerializable(explicitToJson: true)
class Store extends Model<Store> {
  final String phoneNumber;
  final String name;
  final String city;
  final String state;
  final String zipcode;

  Store({
    String phoneNumber = '',
    this.name = '',
    this.city = '',
    this.state = '',
    this.zipcode = '',
    super.created,
    super.updated,
  }) : phoneNumber = phoneNumber.isNotEmpty ? normalizePhoneNumber(phoneNumber) : '';

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);

  @override
  String get uniqueKey => phoneNumber;

  @override
  Store copyWith(
      {String? phoneNumber,
      String? name,
      String? city,
      String? state,
      String? zipcode,
      DateTime? created,
      DateTime? updated}) {
    return Store(
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
  bool equalTo(Store other) {
    return phoneNumber == other.phoneNumber &&
        name == other.name &&
        city == other.city &&
        state == other.state &&
        zipcode == other.zipcode;
  }

  @override
  Store merge(Store other) => _$mergeStore(this, other);

  @override
  Map<String, dynamic> toJson() => _$StoreToJson(this);
}
