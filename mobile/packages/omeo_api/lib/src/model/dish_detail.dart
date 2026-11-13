//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:omeo_api/src/model/analysis_item.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dish_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DishDetail {
  /// Returns a new [DishDetail] instance.
  DishDetail({
    required this.id,

    required this.name,

    this.country,

    this.image,

    this.standardPortionG,

    this.kcalPerPortion,

    this.isFavorite,

    this.aliases,

    this.components,

    this.nutrientsPerPortion,

    this.recipeId,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final Image? image;

  @JsonKey(name: r'standard_portion_g', required: false, includeIfNull: false)
  final num? standardPortionG;

  @JsonKey(name: r'kcal_per_portion', required: false, includeIfNull: false)
  final int? kcalPerPortion;

  @JsonKey(name: r'is_favorite', required: false, includeIfNull: false)
  final bool? isFavorite;

  @JsonKey(name: r'aliases', required: false, includeIfNull: false)
  final List<String>? aliases;

  @JsonKey(name: r'components', required: false, includeIfNull: false)
  final List<AnalysisItem>? components;

  @JsonKey(
    name: r'nutrients_per_portion',
    required: false,
    includeIfNull: false,
  )
  final Nutrients? nutrientsPerPortion;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishDetail &&
          other.id == id &&
          other.name == name &&
          other.country == country &&
          other.image == image &&
          other.standardPortionG == standardPortionG &&
          other.kcalPerPortion == kcalPerPortion &&
          other.isFavorite == isFavorite &&
          other.aliases == aliases &&
          other.components == components &&
          other.nutrientsPerPortion == nutrientsPerPortion &&
          other.recipeId == recipeId;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      country.hashCode +
      (image == null ? 0 : image.hashCode) +
      standardPortionG.hashCode +
      kcalPerPortion.hashCode +
      isFavorite.hashCode +
      aliases.hashCode +
      components.hashCode +
      nutrientsPerPortion.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode);

  factory DishDetail.fromJson(Map<String, dynamic> json) =>
      _$DishDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DishDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
