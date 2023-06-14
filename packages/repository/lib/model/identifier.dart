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

class ItemIdentifier {
  IdentifierType type = UPC();
  String iuid = '';
  String value = '';

  ItemIdentifier();
  ItemIdentifier.withType(this.type);
}
