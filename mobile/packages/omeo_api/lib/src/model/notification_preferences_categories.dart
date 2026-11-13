//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_categories.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPreferencesCategories {
  /// Returns a new [NotificationPreferencesCategories] instance.
  NotificationPreferencesCategories({
    this.mealReminders,

    this.hydration,

    this.weighIn,

    this.programsChallenges,

    this.rewards,

    this.prevention,

    this.campaigns,

    this.subscription,
  });

  @JsonKey(name: r'meal_reminders', required: false, includeIfNull: false)
  final bool? mealReminders;

  @JsonKey(name: r'hydration', required: false, includeIfNull: false)
  final bool? hydration;

  @JsonKey(name: r'weigh_in', required: false, includeIfNull: false)
  final bool? weighIn;

  @JsonKey(name: r'programs_challenges', required: false, includeIfNull: false)
  final bool? programsChallenges;

  @JsonKey(name: r'rewards', required: false, includeIfNull: false)
  final bool? rewards;

  @JsonKey(name: r'prevention', required: false, includeIfNull: false)
  final bool? prevention;

  /// Lié au consentement marketing
  @JsonKey(name: r'campaigns', required: false, includeIfNull: false)
  final bool? campaigns;

  /// Toujours true : les notifications d'abonnement ne se désactivent pas
  @JsonKey(name: r'subscription', required: false, includeIfNull: false)
  final bool? subscription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesCategories &&
          other.mealReminders == mealReminders &&
          other.hydration == hydration &&
          other.weighIn == weighIn &&
          other.programsChallenges == programsChallenges &&
          other.rewards == rewards &&
          other.prevention == prevention &&
          other.campaigns == campaigns &&
          other.subscription == subscription;

  @override
  int get hashCode =>
      mealReminders.hashCode +
      hydration.hashCode +
      weighIn.hashCode +
      programsChallenges.hashCode +
      rewards.hashCode +
      prevention.hashCode +
      campaigns.hashCode +
      subscription.hashCode;

  factory NotificationPreferencesCategories.fromJson(
    Map<String, dynamic> json,
  ) => _$NotificationPreferencesCategoriesFromJson(json);

  Map<String, dynamic> toJson() =>
      _$NotificationPreferencesCategoriesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
