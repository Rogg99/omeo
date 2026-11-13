//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/gauge.dart';
import 'package:omeo_api/src/model/balance.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'day_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DaySummary {
  /// Returns a new [DaySummary] instance.
  DaySummary({
    required this.date,

    required this.kcal,

    required this.protein,

    required this.carbs,

    required this.fat,

    this.fiber,

    this.salt,

    required this.water,

    this.targetAdjustedByActivityKcal,

    this.balance,

    this.mealsCount,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final Gauge kcal;

  @JsonKey(name: r'protein', required: true, includeIfNull: false)
  final Gauge protein;

  @JsonKey(name: r'carbs', required: true, includeIfNull: false)
  final Gauge carbs;

  @JsonKey(name: r'fat', required: true, includeIfNull: false)
  final Gauge fat;

  @JsonKey(name: r'fiber', required: false, includeIfNull: false)
  final Gauge? fiber;

  @JsonKey(name: r'salt', required: false, includeIfNull: false)
  final Gauge? salt;

  @JsonKey(name: r'water', required: true, includeIfNull: false)
  final Gauge water;

  @JsonKey(
    name: r'target_adjusted_by_activity_kcal',
    required: false,
    includeIfNull: false,
  )
  final int? targetAdjustedByActivityKcal;

  @JsonKey(name: r'balance', required: false, includeIfNull: false)
  final Balance? balance;

  @JsonKey(name: r'meals_count', required: false, includeIfNull: false)
  final int? mealsCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DaySummary &&
          other.date == date &&
          other.kcal == kcal &&
          other.protein == protein &&
          other.carbs == carbs &&
          other.fat == fat &&
          other.fiber == fiber &&
          other.salt == salt &&
          other.water == water &&
          other.targetAdjustedByActivityKcal == targetAdjustedByActivityKcal &&
          other.balance == balance &&
          other.mealsCount == mealsCount;

  @override
  int get hashCode =>
      date.hashCode +
      kcal.hashCode +
      protein.hashCode +
      carbs.hashCode +
      fat.hashCode +
      fiber.hashCode +
      salt.hashCode +
      water.hashCode +
      targetAdjustedByActivityKcal.hashCode +
      (balance == null ? 0 : balance.hashCode) +
      mealsCount.hashCode;

  factory DaySummary.fromJson(Map<String, dynamic> json) =>
      _$DaySummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DaySummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
