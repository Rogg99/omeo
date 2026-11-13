//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSummary {
  /// Returns a new [RecipeSummary] instance.
  RecipeSummary({
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
  final RecipeSummaryDifficultyEnum? difficulty;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSummary &&
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
          other.locked == locked;

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
      locked.hashCode;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeSummaryDifficultyEnum {
  @JsonValue(r'easy')
  easy(r'easy'),
  @JsonValue(r'medium')
  medium(r'medium'),
  @JsonValue(r'hard')
  hard(r'hard');

  const RecipeSummaryDifficultyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
