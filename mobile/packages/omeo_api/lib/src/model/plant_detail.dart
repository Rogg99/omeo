//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plant_detail_all_of_contraindications.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/recipe_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plant_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlantDetail {
  /// Returns a new [PlantDetail] instance.
  PlantDetail({
    required this.id,

    required this.commonName,

    required this.scientificName,

    this.image,

    this.tags,

    this.isFavorite,

    required this.traditionalUse,

    required this.nutritionalBenefits,

    required this.precautions,

    this.contraindications,

    required this.disclaimer,

    this.relatedRecipes,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'common_name', required: true, includeIfNull: false)
  final String commonName;

  @JsonKey(name: r'scientific_name', required: true, includeIfNull: false)
  final String scientificName;

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final Image? image;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @JsonKey(name: r'is_favorite', required: false, includeIfNull: false)
  final bool? isFavorite;

  @JsonKey(name: r'traditional_use', required: true, includeIfNull: false)
  final String traditionalUse;

  @JsonKey(name: r'nutritional_benefits', required: true, includeIfNull: false)
  final String nutritionalBenefits;

  @JsonKey(name: r'precautions', required: true, includeIfNull: false)
  final String precautions;

  @JsonKey(name: r'contraindications', required: false, includeIfNull: false)
  final List<PlantDetailAllOfContraindications>? contraindications;

  @JsonKey(name: r'disclaimer', required: true, includeIfNull: false)
  final String disclaimer;

  @JsonKey(name: r'related_recipes', required: false, includeIfNull: false)
  final List<RecipeSummary>? relatedRecipes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantDetail &&
          other.id == id &&
          other.commonName == commonName &&
          other.scientificName == scientificName &&
          other.image == image &&
          other.tags == tags &&
          other.isFavorite == isFavorite &&
          other.traditionalUse == traditionalUse &&
          other.nutritionalBenefits == nutritionalBenefits &&
          other.precautions == precautions &&
          other.contraindications == contraindications &&
          other.disclaimer == disclaimer &&
          other.relatedRecipes == relatedRecipes;

  @override
  int get hashCode =>
      id.hashCode +
      commonName.hashCode +
      scientificName.hashCode +
      image.hashCode +
      tags.hashCode +
      isFavorite.hashCode +
      traditionalUse.hashCode +
      nutritionalBenefits.hashCode +
      precautions.hashCode +
      contraindications.hashCode +
      disclaimer.hashCode +
      relatedRecipes.hashCode;

  factory PlantDetail.fromJson(Map<String, dynamic> json) =>
      _$PlantDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PlantDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
