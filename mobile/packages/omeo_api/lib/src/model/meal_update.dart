//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:omeo_api/src/model/meal_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MealUpdate {
  /// Returns a new [MealUpdate] instance.
  MealUpdate({this.mealType, this.date, this.items, this.portions});

  @JsonKey(name: r'meal_type', required: false, includeIfNull: false)
  final MealType? mealType;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @JsonKey(name: r'items', required: false, includeIfNull: false)
  final List<MealItemInput>? items;

  // minimum: 0.25
  // maximum: 10
  @JsonKey(name: r'portions', required: false, includeIfNull: false)
  final num? portions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealUpdate &&
          other.mealType == mealType &&
          other.date == date &&
          other.items == items &&
          other.portions == portions;

  @override
  int get hashCode =>
      mealType.hashCode + date.hashCode + items.hashCode + portions.hashCode;

  factory MealUpdate.fromJson(Map<String, dynamic> json) =>
      _$MealUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$MealUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
