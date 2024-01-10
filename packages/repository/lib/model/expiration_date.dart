import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'expiration_date.g.dart';
part 'expiration_date.merge.dart';

@immutable
@Mergeable()
@JsonSerializable(explicitToJson: true)
class ExpirationDate extends Model<ExpirationDate> {
  @JsonKey(defaultValue: '')
  final String upc;

  @NullableDateTimeSerializer()
  @JsonKey(defaultValue: null)
  final DateTime? expirationDate;

  ExpirationDate({
    required this.upc,
    required this.expirationDate,
    super.created,
    super.updated,
  });

  factory ExpirationDate.fromJson(Map<String, dynamic> json) => _$ExpirationDateFromJson(json);

  @override
  String get id => "$upc-${expirationDate?.millisecondsSinceEpoch.toString() ?? ''}";

  ExpirationDate copyWith({
    String? upc,
    DateTime? date,
    DateTime? created,
    DateTime? updated,
  }) {
    return ExpirationDate(
      upc: upc ?? this.upc,
      expirationDate: date ?? expirationDate,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(ExpirationDate other) {
    return upc == other.upc && expirationDate == other.expirationDate;
  }

  @override
  ExpirationDate merge(ExpirationDate other) => _$mergeExpirationDate(this, other);

  @override
  Map<String, dynamic> toJson() => _$ExpirationDateToJson(this);
}
