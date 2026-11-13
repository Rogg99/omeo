//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:omeo_api/src/model/meal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'day_detail_meals_by_type_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DayDetailMealsByTypeInner {
  /// Returns a new [DayDetailMealsByTypeInner] instance.
  DayDetailMealsByTypeInner({
    required this.mealType,

    required this.label,

    required this.kcal,

    required this.meals,
  });

  @JsonKey(name: r'meal_type', required: true, includeIfNull: false)
  final MealType mealType;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'meals', required: true, includeIfNull: false)
  final List<Meal> meals;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayDetailMealsByTypeInner &&
          other.mealType == mealType &&
          other.label == label &&
          other.kcal == kcal &&
          other.meals == meals;

  @override
  int get hashCode =>
      mealType.hashCode + label.hashCode + kcal.hashCode + meals.hashCode;

  factory DayDetailMealsByTypeInner.fromJson(Map<String, dynamic> json) =>
      _$DayDetailMealsByTypeInnerFromJson(json);

  Map<String, dynamic> toJson() => _$DayDetailMealsByTypeInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
