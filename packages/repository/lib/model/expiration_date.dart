import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'expiration_date.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ExpirationDate {
  @JsonKey(defaultValue: '')
  final String upc;

  @NullableDateTimeSerializer()
  final DateTime? date;

  @NullableDateTimeSerializer()
  final DateTime? created;

  ExpirationDate({
    required this.upc,
    required this.date,
    DateTime? created,
  }) : created = created ?? DateTime.now();

  factory ExpirationDate.fromJson(Map<String, dynamic> json) => _$ExpirationDateFromJson(json);

  ExpirationDate copyWith({
    String? upc,
    DateTime? date,
    DateTime? created,
  }) {
    return ExpirationDate(
      upc: upc ?? this.upc,
      date: date ?? this.date,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toJson() => _$ExpirationDateToJson(this);
}
