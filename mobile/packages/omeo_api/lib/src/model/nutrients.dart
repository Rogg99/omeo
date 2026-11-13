//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nutrients.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Nutrients {
  /// Returns a new [Nutrients] instance.
  Nutrients({
    required this.kcal,

    required this.proteinG,

    required this.carbsG,

    this.sugarsG,

    required this.fatG,

    this.saturatedFatG,

    this.fiberG,

    this.saltG,
  });

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'protein_g', required: true, includeIfNull: false)
  final num proteinG;

  @JsonKey(name: r'carbs_g', required: true, includeIfNull: false)
  final num carbsG;

  @JsonKey(name: r'sugars_g', required: false, includeIfNull: false)
  final num? sugarsG;

  @JsonKey(name: r'fat_g', required: true, includeIfNull: false)
  final num fatG;

  @JsonKey(name: r'saturated_fat_g', required: false, includeIfNull: false)
  final num? saturatedFatG;

  @JsonKey(name: r'fiber_g', required: false, includeIfNull: false)
  final num? fiberG;

  @JsonKey(name: r'salt_g', required: false, includeIfNull: false)
  final num? saltG;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nutrients &&
          other.kcal == kcal &&
          other.proteinG == proteinG &&
          other.carbsG == carbsG &&
          other.sugarsG == sugarsG &&
          other.fatG == fatG &&
          other.saturatedFatG == saturatedFatG &&
          other.fiberG == fiberG &&
          other.saltG == saltG;

  @override
  int get hashCode =>
      kcal.hashCode +
      proteinG.hashCode +
      carbsG.hashCode +
      sugarsG.hashCode +
      fatG.hashCode +
      saturatedFatG.hashCode +
      fiberG.hashCode +
      saltG.hashCode;

  factory Nutrients.fromJson(Map<String, dynamic> json) =>
      _$NutrientsFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
