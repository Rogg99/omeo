//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_notifications.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsNotifications {
  /// Returns a new [SettingsNotifications] instance.
  SettingsNotifications({
    this.maxPushPerDay,

    this.defaultQuietStart,

    this.defaultQuietEnd,
  });

  @JsonKey(name: r'max_push_per_day', required: false, includeIfNull: false)
  final int? maxPushPerDay;

  @JsonKey(name: r'default_quiet_start', required: false, includeIfNull: false)
  final String? defaultQuietStart;

  @JsonKey(name: r'default_quiet_end', required: false, includeIfNull: false)
  final String? defaultQuietEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsNotifications &&
          other.maxPushPerDay == maxPushPerDay &&
          other.defaultQuietStart == defaultQuietStart &&
          other.defaultQuietEnd == defaultQuietEnd;

  @override
  int get hashCode =>
      maxPushPerDay.hashCode +
      defaultQuietStart.hashCode +
      defaultQuietEnd.hashCode;

  factory SettingsNotifications.fromJson(Map<String, dynamic> json) =>
      _$SettingsNotificationsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsNotificationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
