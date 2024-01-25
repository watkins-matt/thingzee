import 'package:json_annotation/json_annotation.dart';

part 'item_translation.g.dart';

@JsonSerializable(explicitToJson: true)
class ItemTranslation {
  String upc = ''; // generator:unique
  String languageCode = 'en';
  String name = '';
  String variety = '';
  String unitName = '';
  String unitPlural = '';
  String type = '';

  ItemTranslation();
  factory ItemTranslation.fromJson(Map<String, dynamic> json) => _$ItemTranslationFromJson(json);
  Map<String, dynamic> toJson() => _$ItemTranslationToJson(this);
}
