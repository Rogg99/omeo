//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal_item_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MealItemInput {
  /// Returns a new [MealItemInput] instance.
  MealItemInput({required this.foodId, required this.grams});

  @JsonKey(name: r'food_id', required: true, includeIfNull: false)
  final String foodId;

  // minimum: 0
  // maximum: 3000
  @JsonKey(name: r'grams', required: true, includeIfNull: false)
  final num grams;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealItemInput && other.foodId == foodId && other.grams == grams;

  @override
  int get hashCode => foodId.hashCode + grams.hashCode;

  factory MealItemInput.fromJson(Map<String, dynamic> json) =>
      _$MealItemInputFromJson(json);

  Map<String, dynamic> toJson() => _$MealItemInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
