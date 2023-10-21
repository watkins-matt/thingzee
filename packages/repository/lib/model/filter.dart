import 'package:meta/meta.dart';

@immutable
class Filter {
  final bool consumable;
  final bool nonConsumable;
  final bool outsOnly;
  final bool displayBranded;

  const Filter({
    this.consumable = true,
    this.nonConsumable = false,
    this.outsOnly = false,
    this.displayBranded = true,
  });

  Filter copyWith({
    bool? consumable,
    bool? nonConsumable,
    bool? outsOnly,
    bool? displayBranded,
  }) {
    return Filter(
      consumable: consumable ?? this.consumable,
      nonConsumable: nonConsumable ?? this.nonConsumable,
      outsOnly: outsOnly ?? this.outsOnly,
      displayBranded: displayBranded ?? this.displayBranded,
    );
  }
}
