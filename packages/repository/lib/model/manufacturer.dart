import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'manufacturer.g.dart';
part 'manufacturer.merge.dart';

@JsonSerializable()
@immutable
@Mergeable()
class Manufacturer extends Model<Manufacturer> implements Comparable<Manufacturer> {
  final String name;
  final String website;
  final String uid;
  final String parentName;
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

  @override
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
  Manufacturer merge(Manufacturer other) => _$mergeManufacturer(this, other);

  @override
  Map<String, dynamic> toJson() => _$ManufacturerToJson(this);
}
