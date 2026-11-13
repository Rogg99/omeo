//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_referral.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsReferral {
  /// Returns a new [SettingsReferral] instance.
  SettingsReferral({this.daysPerReferral, this.capDays});

  @JsonKey(name: r'days_per_referral', required: false, includeIfNull: false)
  final int? daysPerReferral;

  @JsonKey(name: r'cap_days', required: false, includeIfNull: false)
  final int? capDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsReferral &&
          other.daysPerReferral == daysPerReferral &&
          other.capDays == capDays;

  @override
  int get hashCode => daysPerReferral.hashCode + capDays.hashCode;

  factory SettingsReferral.fromJson(Map<String, dynamic> json) =>
      _$SettingsReferralFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsReferralToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
