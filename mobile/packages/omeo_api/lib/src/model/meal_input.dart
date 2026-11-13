//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/meal_type.dart';
import 'package:omeo_api/src/model/meal_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meal_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MealInput {
  /// Returns a new [MealInput] instance.
  MealInput({
    required this.source_,

    required this.mealType,

    this.date,

    this.eatenAt,

    this.analysisId,

    this.dishId,

    this.recipeId,

    this.portions,

    this.items,

    this.keepPhoto = true,
  });

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final MealInputSource_Enum source_;

  @JsonKey(name: r'meal_type', required: true, includeIfNull: false)
  final MealType mealType;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @JsonKey(name: r'eaten_at', required: false, includeIfNull: false)
  final DateTime? eatenAt;

  /// source = photo|text
  @JsonKey(name: r'analysis_id', required: false, includeIfNull: false)
  final String? analysisId;

  /// source = dish
  @JsonKey(name: r'dish_id', required: false, includeIfNull: false)
  final String? dishId;

  /// source = recipe|program
  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  /// dish/recipe : multiple de la portion standard
  // minimum: 0.25
  // maximum: 10
  @JsonKey(name: r'portions', required: false, includeIfNull: false)
  final num? portions;

  /// Ingrédients validés (corrigés) — obligatoire pour photo|text|foods
  @JsonKey(name: r'items', required: false, includeIfNull: false)
  final List<MealItemInput>? items;

  @JsonKey(
    defaultValue: true,
    name: r'keep_photo',
    required: false,
    includeIfNull: false,
  )
  final bool? keepPhoto;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealInput &&
          other.source_ == source_ &&
          other.mealType == mealType &&
          other.date == date &&
          other.eatenAt == eatenAt &&
          other.analysisId == analysisId &&
          other.dishId == dishId &&
          other.recipeId == recipeId &&
          other.portions == portions &&
          other.items == items &&
          other.keepPhoto == keepPhoto;

  @override
  int get hashCode =>
      source_.hashCode +
      mealType.hashCode +
      date.hashCode +
      eatenAt.hashCode +
      analysisId.hashCode +
      dishId.hashCode +
      recipeId.hashCode +
      portions.hashCode +
      items.hashCode +
      keepPhoto.hashCode;

  factory MealInput.fromJson(Map<String, dynamic> json) =>
      _$MealInputFromJson(json);

  Map<String, dynamic> toJson() => _$MealInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MealInputSource_Enum {
  @JsonValue(r'photo')
  photo(r'photo'),
  @JsonValue(r'text')
  text(r'text'),
  @JsonValue(r'dish')
  dish(r'dish'),
  @JsonValue(r'recipe')
  recipe(r'recipe'),
  @JsonValue(r'foods')
  foods(r'foods'),
  @JsonValue(r'program')
  program(r'program');

  const MealInputSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
