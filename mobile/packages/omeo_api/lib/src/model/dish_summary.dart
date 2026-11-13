//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dish_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DishSummary {
  /// Returns a new [DishSummary] instance.
  DishSummary({
    required this.id,

    required this.name,

    this.country,

    this.image,

    this.standardPortionG,

    this.kcalPerPortion,

    this.isFavorite,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishSummary &&
          other.id == id &&
          other.name == name &&
          other.country == country &&
          other.image == image &&
          other.standardPortionG == standardPortionG &&
          other.kcalPerPortion == kcalPerPortion &&
          other.isFavorite == isFavorite;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      country.hashCode +
      (image == null ? 0 : image.hashCode) +
      standardPortionG.hashCode +
      kcalPerPortion.hashCode +
      isFavorite.hashCode;

  factory DishSummary.fromJson(Map<String, dynamic> json) =>
      _$DishSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DishSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
