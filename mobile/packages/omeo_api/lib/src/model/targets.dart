//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'targets.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Targets {
  /// Returns a new [Targets] instance.
  Targets({
    required this.kcal,

    required this.proteinG,

    required this.carbsG,

    required this.fatG,

    required this.fiberG,

    required this.saltMaxG,

    required this.waterMl,

    this.bmrKcal,

    this.validFrom,

    this.warning,
  });

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'protein_g', required: true, includeIfNull: false)
  final int proteinG;

  @JsonKey(name: r'carbs_g', required: true, includeIfNull: false)
  final int carbsG;

  @JsonKey(name: r'fat_g', required: true, includeIfNull: false)
  final int fatG;

  @JsonKey(name: r'fiber_g', required: true, includeIfNull: false)
  final int fiberG;

  @JsonKey(name: r'salt_max_g', required: true, includeIfNull: false)
  final num saltMaxG;

  @JsonKey(name: r'water_ml', required: true, includeIfNull: false)
  final int waterMl;

  @JsonKey(name: r'bmr_kcal', required: false, includeIfNull: false)
  final int? bmrKcal;

  @JsonKey(name: r'valid_from', required: false, includeIfNull: false)
  final DateTime? validFrom;

  /// Ex. cible contradictoire avec l'objectif (texte traduit)
  @JsonKey(name: r'warning', required: false, includeIfNull: false)
  final String? warning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Targets &&
          other.kcal == kcal &&
          other.proteinG == proteinG &&
          other.carbsG == carbsG &&
          other.fatG == fatG &&
          other.fiberG == fiberG &&
          other.saltMaxG == saltMaxG &&
          other.waterMl == waterMl &&
          other.bmrKcal == bmrKcal &&
          other.validFrom == validFrom &&
          other.warning == warning;

  @override
  int get hashCode =>
      kcal.hashCode +
      proteinG.hashCode +
      carbsG.hashCode +
      fatG.hashCode +
      fiberG.hashCode +
      saltMaxG.hashCode +
      waterMl.hashCode +
      bmrKcal.hashCode +
      validFrom.hashCode +
      (warning == null ? 0 : warning.hashCode);

  factory Targets.fromJson(Map<String, dynamic> json) =>
      _$TargetsFromJson(json);

  Map<String, dynamic> toJson() => _$TargetsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
