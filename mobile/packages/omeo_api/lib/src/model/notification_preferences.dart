//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/notification_preferences_meal_reminder_times.dart';
import 'package:omeo_api/src/model/notification_preferences_categories.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPreferences {
  /// Returns a new [NotificationPreferences] instance.
  NotificationPreferences({
    required this.categories,

    this.mealReminderTimes,

    this.weighInWeekday,

    required this.quietStart,

    required this.quietEnd,
  });

  @JsonKey(name: r'categories', required: true, includeIfNull: false)
  final NotificationPreferencesCategories categories;

  @JsonKey(name: r'meal_reminder_times', required: false, includeIfNull: false)
  final NotificationPreferencesMealReminderTimes? mealReminderTimes;

  // minimum: 1
  // maximum: 7
  @JsonKey(name: r'weigh_in_weekday', required: false, includeIfNull: false)
  final int? weighInWeekday;

  @JsonKey(name: r'quiet_start', required: true, includeIfNull: false)
  final String quietStart;

  @JsonKey(name: r'quiet_end', required: true, includeIfNull: false)
  final String quietEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          other.categories == categories &&
          other.mealReminderTimes == mealReminderTimes &&
          other.weighInWeekday == weighInWeekday &&
          other.quietStart == quietStart &&
          other.quietEnd == quietEnd;

  @override
  int get hashCode =>
      categories.hashCode +
      mealReminderTimes.hashCode +
      weighInWeekday.hashCode +
      quietStart.hashCode +
      quietEnd.hashCode;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
