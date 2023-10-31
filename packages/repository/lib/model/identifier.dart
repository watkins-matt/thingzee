import 'package:json_annotation/json_annotation.dart';

part 'identifier.g.dart';

class ASIN extends IdentifierType {
  @override
  String get label => 'ASIN';
}

class BSKU extends IdentifierType {
  @override
  String get label => 'BSKU';
}

class EAN extends IdentifierType {
  @override
  String get label => 'EAN';
}

class EAN8 extends IdentifierType {
  @override
  String get label => 'EAN8';
}

abstract class IdentifierType {
  String get label;
}

class IdentifierTypeSerializer implements JsonConverter<IdentifierType, String> {
  const IdentifierTypeSerializer();

  @override
  IdentifierType fromJson(String json) {
    switch (json) {
      case 'UPC':
        return UPC();
      case 'UPCE':
        return UPCE();
      case 'EAN':
        return EAN();
      case 'EAN8':
        return EAN8();
      case 'ISBN':
        return ISBN();
      case 'ASIN':
        return ASIN();
      case 'TDPCI':
        return TDPCI();
      case 'BSKU':
        return BSKU();
      case 'WSKU':
        return WSKU();
      default:
        return UPC();
    }
  }

  @override
  String toJson(IdentifierType identifierType) => identifierType.label;
}

class ISBN extends IdentifierType {
  @override
  String get label => 'ISBN';
}

@JsonSerializable(explicitToJson: true)
class ItemIdentifier {
  @IdentifierTypeSerializer()
  IdentifierType type = UPC();
  String uid = '';
  String value = '';

  ItemIdentifier();
  factory ItemIdentifier.fromJson(Map<String, dynamic> json) => _$ItemIdentifierFromJson(json);

  ItemIdentifier.withType(this.type);
  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);
}

class TDPCI extends IdentifierType {
  @override
  String get label => 'TDPCI';
}

class UPC extends IdentifierType {
  @override
  String get label => 'UPC';
}

class UPCE extends IdentifierType {
  @override
  String get label => 'UPCE';
}

class WSKU extends IdentifierType {
  @override
  String get label => 'WSKU';
}
