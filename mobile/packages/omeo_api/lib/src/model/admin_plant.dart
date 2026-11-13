//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_plant.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPlant {
  /// Returns a new [AdminPlant] instance.
  AdminPlant({
    required this.commonName,

    required this.scientificName,

    this.tags,

    required this.traditionalUse,

    required this.nutritionalBenefits,

    required this.precautions,

    this.contraindications,

    this.relatedRecipeIds,

    this.imageUploadId,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'common_name', required: true, includeIfNull: false)
  final Map<String, String> commonName;

  @JsonKey(name: r'scientific_name', required: true, includeIfNull: false)
  final String scientificName;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

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

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPlant &&
          other.commonName == commonName &&
          other.scientificName == scientificName &&
          other.tags == tags &&
          other.traditionalUse == traditionalUse &&
          other.nutritionalBenefits == nutritionalBenefits &&
          other.precautions == precautions &&
          other.contraindications == contraindications &&
          other.relatedRecipeIds == relatedRecipeIds &&
          other.imageUploadId == imageUploadId;

  @override
  int get hashCode =>
      commonName.hashCode +
      scientificName.hashCode +
      tags.hashCode +
      traditionalUse.hashCode +
      nutritionalBenefits.hashCode +
      precautions.hashCode +
      contraindications.hashCode +
      relatedRecipeIds.hashCode +
      imageUploadId.hashCode;

  factory AdminPlant.fromJson(Map<String, dynamic> json) =>
      _$AdminPlantFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPlantToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
