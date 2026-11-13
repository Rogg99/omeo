//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal.dart';
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal_write_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MealWriteResult {
  /// Returns a new [MealWriteResult] instance.
  MealWriteResult({
    required this.meal,

    required this.day,

    this.previousDay,

    required this.rewards,
  });

  @JsonKey(name: r'meal', required: true, includeIfNull: false)
  final Meal meal;

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  /// Si le repas a changé de jour
  @JsonKey(name: r'previous_day', required: false, includeIfNull: false)
  final DaySummary? previousDay;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealWriteResult &&
          other.meal == meal &&
          other.day == day &&
          other.previousDay == previousDay &&
          other.rewards == rewards;

  @override
  int get hashCode =>
      meal.hashCode +
      day.hashCode +
      (previousDay == null ? 0 : previousDay.hashCode) +
      rewards.hashCode;

  factory MealWriteResult.fromJson(Map<String, dynamic> json) =>
      _$MealWriteResultFromJson(json);

  Map<String, dynamic> toJson() => _$MealWriteResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
