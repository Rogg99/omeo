//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_detail_all_of_ingredients.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDetailAllOfIngredients {
  /// Returns a new [RecipeDetailAllOfIngredients] instance.
  RecipeDetailAllOfIngredients({required this.label, this.foodId, this.grams});

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'food_id', required: false, includeIfNull: false)
  final String? foodId;

  @JsonKey(name: r'grams', required: false, includeIfNull: false)
  final num? grams;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDetailAllOfIngredients &&
          other.label == label &&
          other.foodId == foodId &&
          other.grams == grams;

  @override
  int get hashCode => label.hashCode + foodId.hashCode + grams.hashCode;

  factory RecipeDetailAllOfIngredients.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailAllOfIngredientsFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDetailAllOfIngredientsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
