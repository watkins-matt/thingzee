import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'manufacturer.g.dart';

@JsonSerializable()
@immutable
class Manufacturer extends Model<Manufacturer> implements Comparable<Manufacturer> {
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String website;

  @JsonKey(defaultValue: '')
  final String uid;

  @JsonKey(defaultValue: '')
  final String parentName;

  @JsonKey(defaultValue: '')
  final String parentUid;

  Manufacturer({
    this.name = '',
    this.website = '',
    this.uid = '',
    this.parentName = '',
    this.parentUid = '',
    super.created,
    super.updated,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) => _$ManufacturerFromJson(json);

  @override
  String get id => uid; // Assuming 'uid' is the unique identifier for Manufacturer

  @override
  int compareTo(Manufacturer other) {
    return name.compareTo(other.name);
  }

  Manufacturer copyWith({
    String? name,
    String? website,
    String? uid,
    String? parentName,
    String? parentUid,
    DateTime? created,
    DateTime? updated,
  }) {
    return Manufacturer(
      name: name ?? this.name,
      website: website ?? this.website,
      uid: uid ?? this.uid,
      parentName: parentName ?? this.parentName,
      parentUid: parentUid ?? this.parentUid,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Manufacturer other) {
    return uid == other.uid &&
        name == other.name &&
        website == other.website &&
        parentName == other.parentName &&
        parentUid == other.parentUid;
  }

  @override
  Manufacturer merge(Manufacturer other) {
    // Determine the newer updated object
    final newer = (updated != null &&
            updated!.isAfter(other.updated ?? DateTime.fromMillisecondsSinceEpoch(0)))
        ? this
        : other;

    // Use data from the newer updated object unless it's empty or null
    final mergedManufacturer = Manufacturer(
      name: newer.name.isNotEmpty ? newer.name : name,
      website: newer.website.isNotEmpty ? newer.website : website,
      uid: newer.uid.isNotEmpty ? newer.uid : uid,
      parentName: newer.parentName.isNotEmpty ? newer.parentName : parentName,
      parentUid: newer.parentUid.isNotEmpty ? newer.parentUid : parentUid,
      created: _determineOlderCreatedDate(created, other.created),
      updated: DateTime.now(),
    );

    // Check if the merged object is equal to the newer one
    DateTime? finalUpdatedDate = mergedManufacturer.equalTo(newer) ? newer.updated : DateTime.now();

    return Manufacturer(
      name: mergedManufacturer.name,
      website: mergedManufacturer.website,
      uid: mergedManufacturer.uid,
      parentName: mergedManufacturer.parentName,
      parentUid: mergedManufacturer.parentUid,
      created: mergedManufacturer.created,
      updated: finalUpdatedDate ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ManufacturerToJson(this);

  static DateTime _determineOlderCreatedDate(DateTime? date1, DateTime? date2) {
    return date1 ?? date2 ?? DateTime.now();
  }
}
