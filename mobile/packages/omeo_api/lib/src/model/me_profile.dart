//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/sex.dart';
import 'package:omeo_api/src/model/city.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeProfile {
  /// Returns a new [MeProfile] instance.
  MeProfile({
    required this.firstName,

    required this.lastName,

    this.initials,

    this.avatar,

    this.birthDate,

    this.age,

    required this.sex,

    this.city,

    this.cityLabel,

    required this.heightCm,

    required this.currentWeightKg,

    required this.targetWeightKg,

    required this.goals,

    this.activityAdjustment,

    this.timezone,
  });

  @JsonKey(name: r'first_name', required: true, includeIfNull: false)
  final String firstName;

  @JsonKey(name: r'last_name', required: true, includeIfNull: false)
  final String lastName;

  @JsonKey(name: r'initials', required: false, includeIfNull: false)
  final String? initials;

  @JsonKey(name: r'avatar', required: false, includeIfNull: false)
  final Image? avatar;

  @JsonKey(name: r'birth_date', required: false, includeIfNull: false)
  final DateTime? birthDate;

  @JsonKey(name: r'age', required: false, includeIfNull: false)
  final int? age;

  @JsonKey(name: r'sex', required: true, includeIfNull: false)
  final Sex sex;

  @JsonKey(name: r'city', required: false, includeIfNull: false)
  final City? city;

  @JsonKey(name: r'city_label', required: false, includeIfNull: false)
  final String? cityLabel;

  @JsonKey(name: r'height_cm', required: true, includeIfNull: false)
  final num heightCm;

  @JsonKey(name: r'current_weight_kg', required: true, includeIfNull: false)
  final num currentWeightKg;

  @JsonKey(name: r'target_weight_kg', required: true, includeIfNull: false)
  final num targetWeightKg;

  @JsonKey(name: r'goals', required: true, includeIfNull: false)
  final List<Goal> goals;

  @JsonKey(name: r'activity_adjustment', required: false, includeIfNull: false)
  final bool? activityAdjustment;

  @JsonKey(name: r'timezone', required: false, includeIfNull: false)
  final String? timezone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeProfile &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.initials == initials &&
          other.avatar == avatar &&
          other.birthDate == birthDate &&
          other.age == age &&
          other.sex == sex &&
          other.city == city &&
          other.cityLabel == cityLabel &&
          other.heightCm == heightCm &&
          other.currentWeightKg == currentWeightKg &&
          other.targetWeightKg == targetWeightKg &&
          other.goals == goals &&
          other.activityAdjustment == activityAdjustment &&
          other.timezone == timezone;

  @override
  int get hashCode =>
      firstName.hashCode +
      lastName.hashCode +
      initials.hashCode +
      (avatar == null ? 0 : avatar.hashCode) +
      birthDate.hashCode +
      age.hashCode +
      sex.hashCode +
      (city == null ? 0 : city.hashCode) +
      (cityLabel == null ? 0 : cityLabel.hashCode) +
      heightCm.hashCode +
      currentWeightKg.hashCode +
      targetWeightKg.hashCode +
      goals.hashCode +
      activityAdjustment.hashCode +
      timezone.hashCode;

  factory MeProfile.fromJson(Map<String, dynamic> json) =>
      _$MeProfileFromJson(json);

  Map<String, dynamic> toJson() => _$MeProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
