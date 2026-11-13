//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/settings_notifications.dart';
import 'package:omeo_api/src/model/settings_ai.dart';
import 'package:omeo_api/src/model/settings_trial.dart';
import 'package:omeo_api/src/model/settings_challenges.dart';
import 'package:omeo_api/src/model/settings_four_eyes.dart';
import 'package:omeo_api/src/model/settings_nutrition.dart';
import 'package:omeo_api/src/model/settings_billing.dart';
import 'package:omeo_api/src/model/settings_referral.dart';
import 'package:omeo_api/src/model/settings_app.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Settings {
  /// Returns a new [Settings] instance.
  Settings({
    this.reason,

    this.fourEyes,

    this.billing,

    this.nutrition,

    this.ai,

    this.app,

    this.trial,

    this.referral,

    this.challenges,

    this.notifications,
  });

  /// Motif (obligatoire en écriture, audité)
  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @JsonKey(name: r'four_eyes', required: false, includeIfNull: false)
  final SettingsFourEyes? fourEyes;

  @JsonKey(name: r'billing', required: false, includeIfNull: false)
  final SettingsBilling? billing;

  @JsonKey(name: r'nutrition', required: false, includeIfNull: false)
  final SettingsNutrition? nutrition;

  @JsonKey(name: r'ai', required: false, includeIfNull: false)
  final SettingsAi? ai;

  @JsonKey(name: r'app', required: false, includeIfNull: false)
  final SettingsApp? app;

  @JsonKey(name: r'trial', required: false, includeIfNull: false)
  final SettingsTrial? trial;

  @JsonKey(name: r'referral', required: false, includeIfNull: false)
  final SettingsReferral? referral;

  @JsonKey(name: r'challenges', required: false, includeIfNull: false)
  final SettingsChallenges? challenges;

  @JsonKey(name: r'notifications', required: false, includeIfNull: false)
  final SettingsNotifications? notifications;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          other.reason == reason &&
          other.fourEyes == fourEyes &&
          other.billing == billing &&
          other.nutrition == nutrition &&
          other.ai == ai &&
          other.app == app &&
          other.trial == trial &&
          other.referral == referral &&
          other.challenges == challenges &&
          other.notifications == notifications;

  @override
  int get hashCode =>
      reason.hashCode +
      fourEyes.hashCode +
      billing.hashCode +
      nutrition.hashCode +
      ai.hashCode +
      app.hashCode +
      trial.hashCode +
      referral.hashCode +
      challenges.hashCode +
      notifications.hashCode;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
