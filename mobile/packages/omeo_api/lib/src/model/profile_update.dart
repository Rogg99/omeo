//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/sex.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProfileUpdate {
  /// Returns a new [ProfileUpdate] instance.
  ProfileUpdate({
    this.firstName,

    this.lastName,

    this.birthDate,

    this.sex,

    this.cityId,

    this.cityLabel,

    this.heightCm,

    this.targetWeightKg,

    this.goals,

    this.activityAdjustment,

    this.locale,

    this.theme,

    this.unitWeight,

    this.unitHeight,

    this.unitVolume,
  });

  @JsonKey(name: r'first_name', required: false, includeIfNull: false)
  final String? firstName;

  @JsonKey(name: r'last_name', required: false, includeIfNull: false)
  final String? lastName;

  @JsonKey(name: r'birth_date', required: false, includeIfNull: false)
  final DateTime? birthDate;

  @JsonKey(name: r'sex', required: false, includeIfNull: false)
  final Sex? sex;

  @JsonKey(name: r'city_id', required: false, includeIfNull: false)
  final String? cityId;

  @JsonKey(name: r'city_label', required: false, includeIfNull: false)
  final String? cityLabel;

  // minimum: 100
  // maximum: 250
  @JsonKey(name: r'height_cm', required: false, includeIfNull: false)
  final num? heightCm;

  // minimum: 30
  // maximum: 300
  @JsonKey(name: r'target_weight_kg', required: false, includeIfNull: false)
  final num? targetWeightKg;

  @JsonKey(name: r'goals', required: false, includeIfNull: false)
  final List<Goal>? goals;

  @JsonKey(name: r'activity_adjustment', required: false, includeIfNull: false)
  final bool? activityAdjustment;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'theme', required: false, includeIfNull: false)
  final ProfileUpdateThemeEnum? theme;

  @JsonKey(name: r'unit_weight', required: false, includeIfNull: false)
  final ProfileUpdateUnitWeightEnum? unitWeight;

  @JsonKey(name: r'unit_height', required: false, includeIfNull: false)
  final ProfileUpdateUnitHeightEnum? unitHeight;

  @JsonKey(name: r'unit_volume', required: false, includeIfNull: false)
  final ProfileUpdateUnitVolumeEnum? unitVolume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileUpdate &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.birthDate == birthDate &&
          other.sex == sex &&
          other.cityId == cityId &&
          other.cityLabel == cityLabel &&
          other.heightCm == heightCm &&
          other.targetWeightKg == targetWeightKg &&
          other.goals == goals &&
          other.activityAdjustment == activityAdjustment &&
          other.locale == locale &&
          other.theme == theme &&
          other.unitWeight == unitWeight &&
          other.unitHeight == unitHeight &&
          other.unitVolume == unitVolume;

  @override
  int get hashCode =>
      firstName.hashCode +
      lastName.hashCode +
      birthDate.hashCode +
      sex.hashCode +
      (cityId == null ? 0 : cityId.hashCode) +
      (cityLabel == null ? 0 : cityLabel.hashCode) +
      heightCm.hashCode +
      targetWeightKg.hashCode +
      goals.hashCode +
      activityAdjustment.hashCode +
      locale.hashCode +
      theme.hashCode +
      unitWeight.hashCode +
      unitHeight.hashCode +
      unitVolume.hashCode;

  factory ProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProfileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProfileUpdateThemeEnum {
  @JsonValue(r'system')
  system(r'system'),
  @JsonValue(r'light')
  light(r'light'),
  @JsonValue(r'dark')
  dark(r'dark');

  const ProfileUpdateThemeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ProfileUpdateUnitWeightEnum {
  @JsonValue(r'kg')
  kg(r'kg'),
  @JsonValue(r'lb')
  lb(r'lb');

  const ProfileUpdateUnitWeightEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ProfileUpdateUnitHeightEnum {
  @JsonValue(r'cm')
  cm(r'cm'),
  @JsonValue(r'ft')
  ft(r'ft');

  const ProfileUpdateUnitHeightEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ProfileUpdateUnitVolumeEnum {
  @JsonValue(r'cl')
  cl(r'cl'),
  @JsonValue(r'oz')
  oz(r'oz');

  const ProfileUpdateUnitVolumeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
