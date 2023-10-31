import 'package:json_annotation/json_annotation.dart';

part 'manufacturer.g.dart';

@JsonSerializable()
class Manufacturer implements Comparable<Manufacturer> {
  String name = '';
  String website = '';
  String uid = '';

  String parentName = '';
  String parentUid = '';

  Manufacturer();

  factory Manufacturer.fromJson(Map<String, dynamic> json) => _$ManufacturerFromJson(json);

  @override
  int compareTo(Manufacturer other) {
    return name.compareTo(other.name);
  }

  Map<String, dynamic> toJson() => _$ManufacturerToJson(this);
}
