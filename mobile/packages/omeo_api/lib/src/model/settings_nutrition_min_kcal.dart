//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_nutrition_min_kcal.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsNutritionMinKcal {
  /// Returns a new [SettingsNutritionMinKcal] instance.
  SettingsNutritionMinKcal({this.female, this.male});

  @JsonKey(name: r'female', required: false, includeIfNull: false)
  final int? female;

  @JsonKey(name: r'male', required: false, includeIfNull: false)
  final int? male;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsNutritionMinKcal &&
          other.female == female &&
          other.male == male;

  @override
  int get hashCode => female.hashCode + male.hashCode;

  factory SettingsNutritionMinKcal.fromJson(Map<String, dynamic> json) =>
      _$SettingsNutritionMinKcalFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsNutritionMinKcalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
