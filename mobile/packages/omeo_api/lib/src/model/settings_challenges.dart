//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_challenges.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsChallenges {
  /// Returns a new [SettingsChallenges] instance.
  SettingsChallenges({this.defaultSuccessThreshold});

  @JsonKey(
    name: r'default_success_threshold',
    required: false,
    includeIfNull: false,
  )
  final num? defaultSuccessThreshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsChallenges &&
          other.defaultSuccessThreshold == defaultSuccessThreshold;

  @override
  int get hashCode => defaultSuccessThreshold.hashCode;

  factory SettingsChallenges.fromJson(Map<String, dynamic> json) =>
      _$SettingsChallengesFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsChallengesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
