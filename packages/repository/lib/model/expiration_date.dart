import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'expiration_date.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ExpirationDate {
  final String upc;

  @NullableDateTimeSerializer()
  final DateTime? date;

  const ExpirationDate({
    required this.upc,
    this.date,
  });

  factory ExpirationDate.fromJson(Map<String, dynamic> json) => _$ExpirationDateFromJson(json);

  ExpirationDate copyWith({
    String? upc,
    DateTime? date,
  }) {
    return ExpirationDate(
      upc: upc ?? this.upc,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => _$ExpirationDateToJson(this);
}
