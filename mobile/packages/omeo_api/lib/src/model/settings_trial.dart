//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_trial.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsTrial {
  /// Returns a new [SettingsTrial] instance.
  SettingsTrial({this.defaultDays, this.inviteDays});

  @JsonKey(name: r'default_days', required: false, includeIfNull: false)
  final int? defaultDays;

  @JsonKey(name: r'invite_days', required: false, includeIfNull: false)
  final int? inviteDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsTrial &&
          other.defaultDays == defaultDays &&
          other.inviteDays == inviteDays;

  @override
  int get hashCode => defaultDays.hashCode + inviteDays.hashCode;

  factory SettingsTrial.fromJson(Map<String, dynamic> json) =>
      _$SettingsTrialFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsTrialToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
