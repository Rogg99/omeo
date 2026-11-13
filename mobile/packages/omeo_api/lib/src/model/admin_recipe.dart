//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_recipe_steps_inner.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/admin_recipe_ingredients_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_recipe.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminRecipe {
  /// Returns a new [AdminRecipe] instance.
  AdminRecipe({
    required this.name,

    this.description,

    this.country,

    this.prepMinutes,

    this.cookMinutes,

    this.difficulty,

    required this.servings,

    this.tags,

    this.goals,

    this.isFree,

    this.imageUploadId,

    required this.ingredients,

    required this.steps,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'prep_minutes', required: false, includeIfNull: false)
  final int? prepMinutes;

  @JsonKey(name: r'cook_minutes', required: false, includeIfNull: false)
  final int? cookMinutes;

  @JsonKey(name: r'difficulty', required: false, includeIfNull: false)
  final AdminRecipeDifficultyEnum? difficulty;

  // minimum: 1
  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @JsonKey(name: r'goals', required: false, includeIfNull: false)
  final List<Goal>? goals;

  @JsonKey(name: r'is_free', required: false, includeIfNull: false)
  final bool? isFree;

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<AdminRecipeIngredientsInner> ingredients;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<AdminRecipeStepsInner> steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRecipe &&
          other.name == name &&
          other.description == description &&
          other.country == country &&
          other.prepMinutes == prepMinutes &&
          other.cookMinutes == cookMinutes &&
          other.difficulty == difficulty &&
          other.servings == servings &&
          other.tags == tags &&
          other.goals == goals &&
          other.isFree == isFree &&
          other.imageUploadId == imageUploadId &&
          other.ingredients == ingredients &&
          other.steps == steps;

  @override
  int get hashCode =>
      name.hashCode +
      description.hashCode +
      country.hashCode +
      prepMinutes.hashCode +
      cookMinutes.hashCode +
      difficulty.hashCode +
      servings.hashCode +
      tags.hashCode +
      goals.hashCode +
      isFree.hashCode +
      imageUploadId.hashCode +
      ingredients.hashCode +
      steps.hashCode;

  factory AdminRecipe.fromJson(Map<String, dynamic> json) =>
      _$AdminRecipeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminRecipeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminRecipeDifficultyEnum {
  @JsonValue(r'easy')
  easy(r'easy'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'hard')
  hard(r'hard');

  const AdminRecipeDifficultyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
