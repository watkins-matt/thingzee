extension NormalizeUPC on String {
  String normalizeUPC() {
    String result = this;
    if (result.length == 11) {
      result = '0$this';
    }

    return result;
  }
}

class Item implements Comparable<Item> {
  String upc = '';
  String iuid = '';

  String name = '';
  String variety = '';

  String category = '';
  String type = '';

  // Unit information
  int unitCount = 1; // How many units are part of this item, e.g. 12 bottles
  String unitName = ''; // What is the name of the unit, e.g. bottle
  String unitPlural = ''; // What is the plural of the unit, e.g. bottle
  String imageUrl = '';

  bool consumable = true;
  String languageCode = 'en';
  List<ItemTranslation> translations = <ItemTranslation>[];

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }
}

class ItemTranslation {
  String languageCode = 'en';
  String name = '';
  String variety = '';
  String unitName = '';
  String unitPlural = '';
}
