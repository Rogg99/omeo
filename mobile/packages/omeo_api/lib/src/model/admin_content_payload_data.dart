//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/rule_def.dart';
import 'package:omeo_api/src/model/legal_kind.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/level.dart';
import 'package:omeo_api/src/model/admin_recipe_ingredients_inner.dart';
import 'package:omeo_api/src/model/admin_program_days_inner.dart';
import 'package:omeo_api/src/model/admin_workout_steps_inner.dart';
import 'package:omeo_api/src/model/meal_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_content_payload_data.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminContentPayloadData {
  /// Returns a new [AdminContentPayloadData] instance.
  AdminContentPayloadData({
    required this.name,

    this.aliases,

    required this.category,

    required this.kcal,

    required this.proteinG,

    required this.carbsG,

    this.sugarsG,

    required this.fatG,

    this.saturatedFatG,

    this.fiberG,

    this.saltG,

    this.defaultPortionG,

    this.source_,

    required this.country,

    required this.standardPortionG,

    this.imageUploadId,

    this.recipeId,

    required this.components,

    this.description,

    this.prepMinutes,

    this.cookMinutes,

    this.difficulty,

    required this.servings,

    this.tags,

    this.goals,

    this.isFree,

    required this.ingredients,

    required this.steps,

    required this.commonName,

    required this.scientificName,

    required this.traditionalUse,

    required this.nutritionalBenefits,

    required this.precautions,

    this.contraindications,

    this.relatedRecipeIds,

    required this.instructions,

    this.muscles,

    required this.level,

    this.equipment,

    required this.met,

    this.videoUploadId,

    this.subtitleUploadIds,

    required this.goal,

    this.coverUploadId,

    required this.weeks,

    required this.points,

    this.badgeId,

    required this.days,

    required this.durationDays,

    required this.rule,

    this.successThreshold = 0.8,

    this.pointsPerDay,

    this.pointsCompletion,

    required this.code,

    required this.family,

    required this.condition,

    this.bonusPoints,

    this.iconUploadId,

    required this.rank,

    required this.minPoints,

    required this.action,

    this.cap,

    this.capPeriod,

    required this.topic,

    required this.title,

    required this.body,

    required this.trigger,

    required this.tier,

    this.relatedPlantIds,

    required this.question,

    required this.answer,

    this.order,

    this.audience,

    required this.kind,

    this.requiresReaccept,

    required this.timezone,

    this.isSuggested,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  @JsonKey(name: r'aliases', required: false, includeIfNull: false)
  final List<String>? aliases;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  // minimum: 0
  // maximum: 900
  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final num kcal;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'protein_g', required: true, includeIfNull: false)
  final num proteinG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'carbs_g', required: true, includeIfNull: false)
  final num carbsG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'sugars_g', required: false, includeIfNull: false)
  final num? sugarsG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'fat_g', required: true, includeIfNull: false)
  final num fatG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'saturated_fat_g', required: false, includeIfNull: false)
  final num? saturatedFatG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'fiber_g', required: false, includeIfNull: false)
  final num? fiberG;

  // minimum: 0
  // maximum: 100
  @JsonKey(name: r'salt_g', required: false, includeIfNull: false)
  final num? saltG;

  @JsonKey(name: r'default_portion_g', required: false, includeIfNull: false)
  final num? defaultPortionG;

  @JsonKey(name: r'source', required: false, includeIfNull: false)
  final String? source_;

  @JsonKey(name: r'country', required: true, includeIfNull: false)
  final String country;

  @JsonKey(name: r'standard_portion_g', required: true, includeIfNull: false)
  final num standardPortionG;

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'components', required: true, includeIfNull: false)
  final List<MealItemInput> components;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  @JsonKey(name: r'prep_minutes', required: false, includeIfNull: false)
  final int? prepMinutes;

  @JsonKey(name: r'cook_minutes', required: false, includeIfNull: false)
  final int? cookMinutes;

  @JsonKey(name: r'difficulty', required: false, includeIfNull: false)
  final AdminContentPayloadDataDifficultyEnum? difficulty;

  // minimum: 1
  @JsonKey(name: r'servings', required: true, includeIfNull: false)
  final int servings;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @JsonKey(name: r'goals', required: false, includeIfNull: false)
  final List<Goal>? goals;

  @JsonKey(name: r'is_free', required: false, includeIfNull: false)
  final bool? isFree;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<AdminRecipeIngredientsInner> ingredients;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<AdminWorkoutStepsInner> steps;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'common_name', required: true, includeIfNull: false)
  final Map<String, String> commonName;

  @JsonKey(name: r'scientific_name', required: true, includeIfNull: false)
  final String scientificName;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'traditional_use', required: true, includeIfNull: false)
  final Map<String, String> traditionalUse;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'nutritional_benefits', required: true, includeIfNull: false)
  final Map<String, String> nutritionalBenefits;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'precautions', required: true, includeIfNull: false)
  final Map<String, String> precautions;

  @JsonKey(name: r'contraindications', required: false, includeIfNull: false)
  final List<String>? contraindications;

  @JsonKey(name: r'related_recipe_ids', required: false, includeIfNull: false)
  final List<String>? relatedRecipeIds;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'instructions', required: true, includeIfNull: false)
  final Map<String, String> instructions;

  @JsonKey(name: r'muscles', required: false, includeIfNull: false)
  final List<String>? muscles;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final Level level;

  @JsonKey(name: r'equipment', required: false, includeIfNull: false)
  final List<String>? equipment;

  // minimum: 1
  // maximum: 20
  @JsonKey(name: r'met', required: true, includeIfNull: false)
  final num met;

  @JsonKey(name: r'video_upload_id', required: false, includeIfNull: false)
  final String? videoUploadId;

  @JsonKey(name: r'subtitle_upload_ids', required: false, includeIfNull: false)
  final Map<String, String>? subtitleUploadIds;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final Goal goal;

  @JsonKey(name: r'cover_upload_id', required: false, includeIfNull: false)
  final String? coverUploadId;

  // minimum: 1
  // maximum: 52
  @JsonKey(name: r'weeks', required: true, includeIfNull: false)
  final int weeks;

  // minimum: 0
  @JsonKey(name: r'points', required: true, includeIfNull: false)
  final int points;

  @JsonKey(name: r'badge_id', required: false, includeIfNull: false)
  final String? badgeId;

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<AdminProgramDaysInner> days;

  // minimum: 7
  // maximum: 30
  @JsonKey(name: r'duration_days', required: true, includeIfNull: false)
  final int durationDays;

  @JsonKey(name: r'rule', required: true, includeIfNull: false)
  final RuleDef rule;

  // minimum: 0.5
  // maximum: 1
  @JsonKey(
    defaultValue: 0.8,
    name: r'success_threshold',
    required: false,
    includeIfNull: false,
  )
  final num? successThreshold;

  @JsonKey(name: r'points_per_day', required: false, includeIfNull: false)
  final int? pointsPerDay;

  @JsonKey(name: r'points_completion', required: false, includeIfNull: false)
  final int? pointsCompletion;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'family', required: true, includeIfNull: false)
  final AdminContentPayloadDataFamilyEnum family;

  @JsonKey(name: r'condition', required: true, includeIfNull: false)
  final Map<String, Object> condition;

  @JsonKey(name: r'bonus_points', required: false, includeIfNull: false)
  final int? bonusPoints;

  @JsonKey(name: r'icon_upload_id', required: false, includeIfNull: false)
  final String? iconUploadId;

  // minimum: 1
  @JsonKey(name: r'rank', required: true, includeIfNull: false)
  final int rank;

  // minimum: 0
  @JsonKey(name: r'min_points', required: true, includeIfNull: false)
  final int minPoints;

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'cap', required: false, includeIfNull: false)
  final int? cap;

  @JsonKey(name: r'cap_period', required: false, includeIfNull: false)
  final AdminContentPayloadDataCapPeriodEnum? capPeriod;

  @JsonKey(name: r'topic', required: true, includeIfNull: false)
  final AdminContentPayloadDataTopicEnum topic;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final Map<String, String> title;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final Map<String, String> body;

  @JsonKey(name: r'trigger', required: true, includeIfNull: false)
  final Map<String, Object> trigger;

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final AdminContentPayloadDataTierEnum tier;

  @JsonKey(name: r'related_plant_ids', required: false, includeIfNull: false)
  final List<String>? relatedPlantIds;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'question', required: true, includeIfNull: false)
  final Map<String, String> question;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'answer', required: true, includeIfNull: false)
  final Map<String, String> answer;

  @JsonKey(name: r'order', required: false, includeIfNull: false)
  final int? order;

  @JsonKey(name: r'audience', required: false, includeIfNull: false)
  final AdminContentPayloadDataAudienceEnum? audience;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final LegalKind kind;

  @JsonKey(name: r'requires_reaccept', required: false, includeIfNull: false)
  final bool? requiresReaccept;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @JsonKey(name: r'is_suggested', required: false, includeIfNull: false)
  final bool? isSuggested;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminContentPayloadData &&
          other.name == name &&
          other.aliases == aliases &&
          other.category == category &&
          other.kcal == kcal &&
          other.proteinG == proteinG &&
          other.carbsG == carbsG &&
          other.sugarsG == sugarsG &&
          other.fatG == fatG &&
          other.saturatedFatG == saturatedFatG &&
          other.fiberG == fiberG &&
          other.saltG == saltG &&
          other.defaultPortionG == defaultPortionG &&
          other.source_ == source_ &&
          other.country == country &&
          other.standardPortionG == standardPortionG &&
          other.imageUploadId == imageUploadId &&
          other.recipeId == recipeId &&
          other.components == components &&
          other.description == description &&
          other.prepMinutes == prepMinutes &&
          other.cookMinutes == cookMinutes &&
          other.difficulty == difficulty &&
          other.servings == servings &&
          other.tags == tags &&
          other.goals == goals &&
          other.isFree == isFree &&
          other.ingredients == ingredients &&
          other.steps == steps &&
          other.commonName == commonName &&
          other.scientificName == scientificName &&
          other.traditionalUse == traditionalUse &&
          other.nutritionalBenefits == nutritionalBenefits &&
          other.precautions == precautions &&
          other.contraindications == contraindications &&
          other.relatedRecipeIds == relatedRecipeIds &&
          other.instructions == instructions &&
          other.muscles == muscles &&
          other.level == level &&
          other.equipment == equipment &&
          other.met == met &&
          other.videoUploadId == videoUploadId &&
          other.subtitleUploadIds == subtitleUploadIds &&
          other.goal == goal &&
          other.coverUploadId == coverUploadId &&
          other.weeks == weeks &&
          other.points == points &&
          other.badgeId == badgeId &&
          other.days == days &&
          other.durationDays == durationDays &&
          other.rule == rule &&
          other.successThreshold == successThreshold &&
          other.pointsPerDay == pointsPerDay &&
          other.pointsCompletion == pointsCompletion &&
          other.code == code &&
          other.family == family &&
          other.condition == condition &&
          other.bonusPoints == bonusPoints &&
          other.iconUploadId == iconUploadId &&
          other.rank == rank &&
          other.minPoints == minPoints &&
          other.action == action &&
          other.cap == cap &&
          other.capPeriod == capPeriod &&
          other.topic == topic &&
          other.title == title &&
          other.body == body &&
          other.trigger == trigger &&
          other.tier == tier &&
          other.relatedPlantIds == relatedPlantIds &&
          other.question == question &&
          other.answer == answer &&
          other.order == order &&
          other.audience == audience &&
          other.kind == kind &&
          other.requiresReaccept == requiresReaccept &&
          other.timezone == timezone &&
          other.isSuggested == isSuggested;

  @override
  int get hashCode =>
      name.hashCode +
      aliases.hashCode +
      category.hashCode +
      kcal.hashCode +
      proteinG.hashCode +
      carbsG.hashCode +
      sugarsG.hashCode +
      fatG.hashCode +
      saturatedFatG.hashCode +
      fiberG.hashCode +
      saltG.hashCode +
      defaultPortionG.hashCode +
      source_.hashCode +
      country.hashCode +
      standardPortionG.hashCode +
      imageUploadId.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      components.hashCode +
      description.hashCode +
      prepMinutes.hashCode +
      cookMinutes.hashCode +
      difficulty.hashCode +
      servings.hashCode +
      tags.hashCode +
      goals.hashCode +
      isFree.hashCode +
      ingredients.hashCode +
      steps.hashCode +
      commonName.hashCode +
      scientificName.hashCode +
      traditionalUse.hashCode +
      nutritionalBenefits.hashCode +
      precautions.hashCode +
      contraindications.hashCode +
      relatedRecipeIds.hashCode +
      instructions.hashCode +
      muscles.hashCode +
      level.hashCode +
      equipment.hashCode +
      met.hashCode +
      videoUploadId.hashCode +
      subtitleUploadIds.hashCode +
      goal.hashCode +
      coverUploadId.hashCode +
      weeks.hashCode +
      points.hashCode +
      (badgeId == null ? 0 : badgeId.hashCode) +
      days.hashCode +
      durationDays.hashCode +
      rule.hashCode +
      successThreshold.hashCode +
      pointsPerDay.hashCode +
      pointsCompletion.hashCode +
      code.hashCode +
      family.hashCode +
      condition.hashCode +
      bonusPoints.hashCode +
      iconUploadId.hashCode +
      rank.hashCode +
      minPoints.hashCode +
      action.hashCode +
      (cap == null ? 0 : cap.hashCode) +
      capPeriod.hashCode +
      topic.hashCode +
      title.hashCode +
      body.hashCode +
      trigger.hashCode +
      tier.hashCode +
      relatedPlantIds.hashCode +
      question.hashCode +
      answer.hashCode +
      order.hashCode +
      audience.hashCode +
      kind.hashCode +
      requiresReaccept.hashCode +
      timezone.hashCode +
      isSuggested.hashCode;

  factory AdminContentPayloadData.fromJson(Map<String, dynamic> json) =>
      _$AdminContentPayloadDataFromJson(json);

  Map<String, dynamic> toJson() => _$AdminContentPayloadDataToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminContentPayloadDataDifficultyEnum {
  @JsonValue(r'easy')
  easy(r'easy'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'hard')
  hard(r'hard');

  const AdminContentPayloadDataDifficultyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminContentPayloadDataFamilyEnum {
  @JsonValue(r'streak')
  streak(r'streak'),
  @JsonValue(r'nutrition')
  nutrition(r'nutrition'),
  @JsonValue(r'hydration')
  hydration(r'hydration'),
  @JsonValue(r'activity')
  activity(r'activity'),
  @JsonValue(r'challenge')
  challenge(r'challenge'),
  @JsonValue(r'program')
  program(r'program'),
  @JsonValue(r'discovery')
  discovery(r'discovery'),
  @JsonValue(r'referral')
  referral(r'referral');

  const AdminContentPayloadDataFamilyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminContentPayloadDataCapPeriodEnum {
  @JsonValue(r'day')
  day(r'day'),
  @JsonValue(r'week')
  week(r'week'),
  @JsonValue(r'none')
  none(r'none');

  const AdminContentPayloadDataCapPeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminContentPayloadDataTopicEnum {
  @JsonValue(r'water')
  water(r'water'),
  @JsonValue(r'salt')
  salt(r'salt'),
  @JsonValue(r'sugar')
  sugar(r'sugar'),
  @JsonValue(r'fiber')
  fiber(r'fiber'),
  @JsonValue(r'activity')
  activity(r'activity'),
  @JsonValue(r'protein')
  protein(r'protein');

  const AdminContentPayloadDataTopicEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminContentPayloadDataTierEnum {
  @JsonValue(r'free')
  free(r'free'),
  @JsonValue(r'plus')
  plus(r'plus');

  const AdminContentPayloadDataTierEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminContentPayloadDataAudienceEnum {
  @JsonValue(r'app')
  app(r'app'),
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'both')
  both(r'both');

  const AdminContentPayloadDataAudienceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
