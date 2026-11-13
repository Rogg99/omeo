//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/sex.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'onboarding_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OnboardingProfile {
  /// Returns a new [OnboardingProfile] instance.
  OnboardingProfile({
    required this.firstName,

    required this.lastName,

    required this.birthDate,

    required this.sex,

    this.cityId,

    this.cityLabel,

    required this.heightCm,

    required this.weightKg,

    required this.targetWeightKg,

    required this.goals,

    this.locale,

    this.timezone,
  });

  @JsonKey(name: r'first_name', required: true, includeIfNull: false)
  final String firstName;

  @JsonKey(name: r'last_name', required: true, includeIfNull: false)
  final String lastName;

  @JsonKey(name: r'birth_date', required: true, includeIfNull: false)
  final DateTime birthDate;

  @JsonKey(name: r'sex', required: true, includeIfNull: false)
  final Sex sex;

  @JsonKey(name: r'city_id', required: false, includeIfNull: false)
  final String? cityId;

  @JsonKey(name: r'city_label', required: false, includeIfNull: false)
  final String? cityLabel;

  // minimum: 100
  // maximum: 250
  @JsonKey(name: r'height_cm', required: true, includeIfNull: false)
  final num heightCm;

  // minimum: 30
  // maximum: 300
  @JsonKey(name: r'weight_kg', required: true, includeIfNull: false)
  final num weightKg;

  // minimum: 30
  // maximum: 300
  @JsonKey(name: r'target_weight_kg', required: true, includeIfNull: false)
  final num targetWeightKg;

  @JsonKey(name: r'goals', required: true, includeIfNull: false)
  final Set<Goal> goals;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'timezone', required: false, includeIfNull: false)
  final String? timezone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingProfile &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.birthDate == birthDate &&
          other.sex == sex &&
          other.cityId == cityId &&
          other.cityLabel == cityLabel &&
          other.heightCm == heightCm &&
          other.weightKg == weightKg &&
          other.targetWeightKg == targetWeightKg &&
          other.goals == goals &&
          other.locale == locale &&
          other.timezone == timezone;

  @override
  int get hashCode =>
      firstName.hashCode +
      lastName.hashCode +
      birthDate.hashCode +
      sex.hashCode +
      cityId.hashCode +
      cityLabel.hashCode +
      heightCm.hashCode +
      weightKg.hashCode +
      targetWeightKg.hashCode +
      goals.hashCode +
      locale.hashCode +
      timezone.hashCode;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) =>
      _$OnboardingProfileFromJson(json);

  Map<String, dynamic> toJson() => _$OnboardingProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
