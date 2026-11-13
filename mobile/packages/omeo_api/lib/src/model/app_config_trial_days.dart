//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config_trial_days.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfigTrialDays {
  /// Returns a new [AppConfigTrialDays] instance.
  AppConfigTrialDays({this.default_, this.withInvite});

  @JsonKey(name: r'default', required: false, includeIfNull: false)
  final int? default_;

  @JsonKey(name: r'with_invite', required: false, includeIfNull: false)
  final int? withInvite;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigTrialDays &&
          other.default_ == default_ &&
          other.withInvite == withInvite;

  @override
  int get hashCode => default_.hashCode + withInvite.hashCode;

  factory AppConfigTrialDays.fromJson(Map<String, dynamic> json) =>
      _$AppConfigTrialDaysFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigTrialDaysToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
