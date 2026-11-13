//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_food.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFood {
  /// Returns a new [AdminFood] instance.
  AdminFood({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFood &&
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
          other.source_ == source_;

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
      source_.hashCode;

  factory AdminFood.fromJson(Map<String, dynamic> json) =>
      _$AdminFoodFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFoodToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
