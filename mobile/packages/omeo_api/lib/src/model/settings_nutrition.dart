//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/settings_nutrition_min_kcal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_nutrition.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsNutrition {
  /// Returns a new [SettingsNutrition] instance.
  SettingsNutrition({
    this.activityFactor,

    this.loseWeightDeficit,

    this.gainMuscleSurplus,

    this.minKcal,

    this.proteinGPerKg,

    this.fatRatio,

    this.waterMlPerKg,

    this.waterMlPerActiveHour,

    this.fiberG,

    this.saltMaxG,

    this.activityBonusRatio,

    this.kcalTargetTolerance,
  });

  @JsonKey(name: r'activity_factor', required: false, includeIfNull: false)
  final num? activityFactor;

  /// 0.15 à 0.20
  @JsonKey(name: r'lose_weight_deficit', required: false, includeIfNull: false)
  final num? loseWeightDeficit;

  @JsonKey(name: r'gain_muscle_surplus', required: false, includeIfNull: false)
  final num? gainMuscleSurplus;

  @JsonKey(name: r'min_kcal', required: false, includeIfNull: false)
  final SettingsNutritionMinKcal? minKcal;

  @JsonKey(name: r'protein_g_per_kg', required: false, includeIfNull: false)
  final Map<String, num>? proteinGPerKg;

  @JsonKey(name: r'fat_ratio', required: false, includeIfNull: false)
  final Map<String, num>? fatRatio;

  @JsonKey(name: r'water_ml_per_kg', required: false, includeIfNull: false)
  final num? waterMlPerKg;

  @JsonKey(
    name: r'water_ml_per_active_hour',
    required: false,
    includeIfNull: false,
  )
  final int? waterMlPerActiveHour;

  @JsonKey(name: r'fiber_g', required: false, includeIfNull: false)
  final SettingsNutritionMinKcal? fiberG;

  @JsonKey(name: r'salt_max_g', required: false, includeIfNull: false)
  final num? saltMaxG;

  /// 0.5 = moitié de l'excédent
  @JsonKey(name: r'activity_bonus_ratio', required: false, includeIfNull: false)
  final num? activityBonusRatio;

  /// 0.10
  @JsonKey(
    name: r'kcal_target_tolerance',
    required: false,
    includeIfNull: false,
  )
  final num? kcalTargetTolerance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsNutrition &&
          other.activityFactor == activityFactor &&
          other.loseWeightDeficit == loseWeightDeficit &&
          other.gainMuscleSurplus == gainMuscleSurplus &&
          other.minKcal == minKcal &&
          other.proteinGPerKg == proteinGPerKg &&
          other.fatRatio == fatRatio &&
          other.waterMlPerKg == waterMlPerKg &&
          other.waterMlPerActiveHour == waterMlPerActiveHour &&
          other.fiberG == fiberG &&
          other.saltMaxG == saltMaxG &&
          other.activityBonusRatio == activityBonusRatio &&
          other.kcalTargetTolerance == kcalTargetTolerance;

  @override
  int get hashCode =>
      activityFactor.hashCode +
      loseWeightDeficit.hashCode +
      gainMuscleSurplus.hashCode +
      minKcal.hashCode +
      proteinGPerKg.hashCode +
      fatRatio.hashCode +
      waterMlPerKg.hashCode +
      waterMlPerActiveHour.hashCode +
      fiberG.hashCode +
      saltMaxG.hashCode +
      activityBonusRatio.hashCode +
      kcalTargetTolerance.hashCode;

  factory SettingsNutrition.fromJson(Map<String, dynamic> json) =>
      _$SettingsNutritionFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsNutritionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
