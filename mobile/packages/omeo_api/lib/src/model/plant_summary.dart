//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plant_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlantSummary {
  /// Returns a new [PlantSummary] instance.
  PlantSummary({
    required this.id,

    required this.commonName,

    required this.scientificName,

    this.image,

    this.tags,

    this.isFavorite,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantSummary &&
          other.id == id &&
          other.commonName == commonName &&
          other.scientificName == scientificName &&
          other.image == image &&
          other.tags == tags &&
          other.isFavorite == isFavorite;

  @override
  int get hashCode =>
      id.hashCode +
      commonName.hashCode +
      scientificName.hashCode +
      image.hashCode +
      tags.hashCode +
      isFavorite.hashCode;

  factory PlantSummary.fromJson(Map<String, dynamic> json) =>
      _$PlantSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PlantSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
