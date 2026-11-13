//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:omeo_api/src/model/plant_summary.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/recipe_detail_all_of_steps.dart';
import 'package:omeo_api/src/model/recipe_detail_all_of_ingredients.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeDetail {
  /// Returns a new [RecipeDetail] instance.
  RecipeDetail({
    required this.id,

    required this.name,

    this.country,

    this.image,

    required this.totalMinutes,

    this.difficulty,

    this.kcalPerServing,

    this.tags,

    this.tagLabels,

    this.isFavorite,

    required this.locked,

    this.description,

    this.prepMinutes,

    this.cookMinutes,

    required this.servings,

    required this.ingredients,

    required this.steps,

    required this.nutrientsPerServing,

    this.relatedPlants,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final Image? image;

  @JsonKey(name: r'total_minutes', required: true, includeIfNull: false)
  final int totalMinutes;

  @JsonKey(name: r'difficulty', required: false, includeIfNull: false)
  final RecipeDetailDifficultyEnum? difficulty;

  @JsonKey(name: r'kcal_per_serving', required: false, includeIfNull: false)
  final int? kcalPerServing;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @JsonKey(name: r'tag_labels', required: false, includeIfNull: false)
  final List<String>? tagLabels;

  @JsonKey(name: r'is_favorite', required: false, includeIfNull: false)
  final bool? isFavorite;

  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'prep_minutes', required: false, includeIfNull: false)
  final int? prepMinutes;

  @JsonKey(name: r'cook_minutes', required: false, includeIfNull: false)
  final int? cookMinutes;

  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<RecipeDetailAllOfIngredients> ingredients;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<RecipeDetailAllOfSteps> steps;

  @JsonKey(name: r'nutrients_per_serving', required: true, includeIfNull: false)
  final Nutrients nutrientsPerServing;

  @JsonKey(name: r'related_plants', required: false, includeIfNull: false)
  final List<PlantSummary>? relatedPlants;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDetail &&
          other.id == id &&
          other.name == name &&
          other.country == country &&
          other.image == image &&
          other.totalMinutes == totalMinutes &&
          other.difficulty == difficulty &&
          other.kcalPerServing == kcalPerServing &&
          other.tags == tags &&
          other.tagLabels == tagLabels &&
          other.isFavorite == isFavorite &&
          other.locked == locked &&
          other.description == description &&
          other.prepMinutes == prepMinutes &&
          other.cookMinutes == cookMinutes &&
          other.servings == servings &&
          other.ingredients == ingredients &&
          other.steps == steps &&
          other.nutrientsPerServing == nutrientsPerServing &&
          other.relatedPlants == relatedPlants;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      country.hashCode +
      image.hashCode +
      totalMinutes.hashCode +
      difficulty.hashCode +
      kcalPerServing.hashCode +
      tags.hashCode +
      tagLabels.hashCode +
      isFavorite.hashCode +
      locked.hashCode +
      description.hashCode +
      prepMinutes.hashCode +
      cookMinutes.hashCode +
      servings.hashCode +
      ingredients.hashCode +
      steps.hashCode +
      nutrientsPerServing.hashCode +
      relatedPlants.hashCode;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeDetailDifficultyEnum {
  @JsonValue(r'easy')
  easy(r'easy'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'hard')
  hard(r'hard');

  const RecipeDetailDifficultyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
