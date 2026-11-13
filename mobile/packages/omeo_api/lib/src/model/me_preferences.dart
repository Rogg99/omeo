//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_preferences.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MePreferences {
  /// Returns a new [MePreferences] instance.
  MePreferences({
    this.theme,

    this.unitWeight,

    this.unitHeight,

    this.unitVolume,
  });

  @JsonKey(name: r'theme', required: false, includeIfNull: false)
  final MePreferencesThemeEnum? theme;

  @JsonKey(name: r'unit_weight', required: false, includeIfNull: false)
  final MePreferencesUnitWeightEnum? unitWeight;

  @JsonKey(name: r'unit_height', required: false, includeIfNull: false)
  final MePreferencesUnitHeightEnum? unitHeight;

  @JsonKey(name: r'unit_volume', required: false, includeIfNull: false)
  final MePreferencesUnitVolumeEnum? unitVolume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MePreferences &&
          other.theme == theme &&
          other.unitWeight == unitWeight &&
          other.unitHeight == unitHeight &&
          other.unitVolume == unitVolume;

  @override
  int get hashCode =>
      theme.hashCode +
      unitWeight.hashCode +
      unitHeight.hashCode +
      unitVolume.hashCode;

  factory MePreferences.fromJson(Map<String, dynamic> json) =>
      _$MePreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$MePreferencesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MePreferencesThemeEnum {
  @JsonValue(r'system')
  system(r'system'),
  @JsonValue(r'light')
  light(r'light'),
  @JsonValue(r'dark')
  dark(r'dark');

  const MePreferencesThemeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MePreferencesUnitWeightEnum {
  @JsonValue(r'kg')
  kg(r'kg'),
  @JsonValue(r'lb')
  lb(r'lb');

  const MePreferencesUnitWeightEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MePreferencesUnitHeightEnum {
  @JsonValue(r'cm')
  cm(r'cm'),
  @JsonValue(r'ft')
  ft(r'ft');

  const MePreferencesUnitHeightEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum MePreferencesUnitVolumeEnum {
  @JsonValue(r'cl')
  cl(r'cl'),
  @JsonValue(r'oz')
  oz(r'oz');

  const MePreferencesUnitVolumeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
