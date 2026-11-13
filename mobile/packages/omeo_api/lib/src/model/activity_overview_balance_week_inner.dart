//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_overview_balance_week_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityOverviewBalanceWeekInner {
  /// Returns a new [ActivityOverviewBalanceWeekInner] instance.
  ActivityOverviewBalanceWeekInner({
    required this.date,

    required this.consumedKcal,

    required this.burnedKcal,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'consumed_kcal', required: true, includeIfNull: false)
  final int consumedKcal;

  @JsonKey(name: r'burned_kcal', required: true, includeIfNull: false)
  final int burnedKcal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityOverviewBalanceWeekInner &&
          other.date == date &&
          other.consumedKcal == consumedKcal &&
          other.burnedKcal == burnedKcal;

  @override
  int get hashCode =>
      date.hashCode + consumedKcal.hashCode + burnedKcal.hashCode;

  factory ActivityOverviewBalanceWeekInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivityOverviewBalanceWeekInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ActivityOverviewBalanceWeekInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
