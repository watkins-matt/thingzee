import 'package:json_annotation/json_annotation.dart';

part 'manufacturer.g.dart';

@JsonSerializable()
class Manufacturer implements Comparable<Manufacturer> {
  String name = '';
  String website = '';
  String muid = '';

  String parentName = '';
  String parentMuid = '';

  Manufacturer();

  @override
  int compareTo(Manufacturer other) {
    return name.compareTo(other.name);
  }

  factory Manufacturer.fromJson(Map<String, dynamic> json) => _$ManufacturerFromJson(json);
  Map<String, dynamic> toJson() => _$ManufacturerToJson(this);
}
