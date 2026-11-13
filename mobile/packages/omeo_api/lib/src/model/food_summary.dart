//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FoodSummary {
  /// Returns a new [FoodSummary] instance.
  FoodSummary({
    required this.id,

    required this.name,

    this.matchedAlias,

    this.category,

    this.defaultPortionG,

    required this.per100g,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'matched_alias', required: false, includeIfNull: false)
  final String? matchedAlias;

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final String? category;

  @JsonKey(name: r'default_portion_g', required: false, includeIfNull: false)
  final num? defaultPortionG;

  @JsonKey(name: r'per_100g', required: true, includeIfNull: false)
  final Nutrients per100g;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodSummary &&
          other.id == id &&
          other.name == name &&
          other.matchedAlias == matchedAlias &&
          other.category == category &&
          other.defaultPortionG == defaultPortionG &&
          other.per100g == per100g;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      (matchedAlias == null ? 0 : matchedAlias.hashCode) +
      category.hashCode +
      (defaultPortionG == null ? 0 : defaultPortionG.hashCode) +
      per100g.hashCode;

  factory FoodSummary.fromJson(Map<String, dynamic> json) =>
      _$FoodSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
