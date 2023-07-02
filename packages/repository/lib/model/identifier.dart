import 'package:json_annotation/json_annotation.dart';

part 'identifier.g.dart';

abstract class IdentifierType {
  String get label;
}

class UPC extends IdentifierType {
  @override
  String get label => 'UPC';
}

class UPCE extends IdentifierType {
  @override
  String get label => 'UPCE';
}

class EAN extends IdentifierType {
  @override
  String get label => 'EAN';
}

class EAN8 extends IdentifierType {
  @override
  String get label => 'EAN8';
}

class ISBN extends IdentifierType {
  @override
  String get label => 'ISBN';
}

class ASIN extends IdentifierType {
  @override
  String get label => 'ASIN';
}

class TDPCI extends IdentifierType {
  @override
  String get label => 'TDPCI';
}

class BSKU extends IdentifierType {
  @override
  String get label => 'BSKU';
}

class WSKU extends IdentifierType {
  @override
  String get label => 'WSKU';
}

@JsonSerializable(explicitToJson: true)
class ItemIdentifier {
  @IdentifierTypeSerializer()
  IdentifierType type = UPC();
  String iuid = '';
  String value = '';

  ItemIdentifier();
  ItemIdentifier.withType(this.type);

  factory ItemIdentifier.fromJson(Map<String, dynamic> json) => _$ItemIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);
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
