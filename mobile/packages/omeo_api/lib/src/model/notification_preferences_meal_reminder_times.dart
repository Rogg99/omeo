//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_meal_reminder_times.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPreferencesMealReminderTimes {
  /// Returns a new [NotificationPreferencesMealReminderTimes] instance.
  NotificationPreferencesMealReminderTimes({
    this.breakfast,

    this.lunch,

    this.dinner,
  });

  @JsonKey(name: r'breakfast', required: false, includeIfNull: false)
  final String? breakfast;

  @JsonKey(name: r'lunch', required: false, includeIfNull: false)
  final String? lunch;

  @JsonKey(name: r'dinner', required: false, includeIfNull: false)
  final String? dinner;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesMealReminderTimes &&
          other.breakfast == breakfast &&
          other.lunch == lunch &&
          other.dinner == dinner;

  @override
  int get hashCode => breakfast.hashCode + lunch.hashCode + dinner.hashCode;

  factory NotificationPreferencesMealReminderTimes.fromJson(
    Map<String, dynamic> json,
  ) => _$NotificationPreferencesMealReminderTimesFromJson(json);

  Map<String, dynamic> toJson() =>
      _$NotificationPreferencesMealReminderTimesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
