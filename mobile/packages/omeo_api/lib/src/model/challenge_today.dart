//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'challenge_today.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChallengeToday {
  /// Returns a new [ChallengeToday] instance.
  ChallengeToday({
    required this.participationId,

    required this.name,

    required this.dayIndex,

    required this.durationDays,

    required this.todayStatus,

    this.todayProgress,

    this.todayLabel,

    this.canCheck,
  });

  @JsonKey(name: r'participation_id', required: true, includeIfNull: false)
  final String participationId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'day_index', required: true, includeIfNull: false)
  final int dayIndex;

  @JsonKey(name: r'duration_days', required: true, includeIfNull: false)
  final int durationDays;

  @JsonKey(name: r'today_status', required: true, includeIfNull: false)
  final ChallengeTodayTodayStatusEnum todayStatus;

  @JsonKey(name: r'today_progress', required: false, includeIfNull: false)
  final num? todayProgress;

  @JsonKey(name: r'today_label', required: false, includeIfNull: false)
  final String? todayLabel;

  @JsonKey(name: r'can_check', required: false, includeIfNull: false)
  final bool? canCheck;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeToday &&
          other.participationId == participationId &&
          other.name == name &&
          other.dayIndex == dayIndex &&
          other.durationDays == durationDays &&
          other.todayStatus == todayStatus &&
          other.todayProgress == todayProgress &&
          other.todayLabel == todayLabel &&
          other.canCheck == canCheck;

  @override
  int get hashCode =>
      participationId.hashCode +
      name.hashCode +
      dayIndex.hashCode +
      durationDays.hashCode +
      todayStatus.hashCode +
      (todayProgress == null ? 0 : todayProgress.hashCode) +
      todayLabel.hashCode +
      canCheck.hashCode;

  factory ChallengeToday.fromJson(Map<String, dynamic> json) =>
      _$ChallengeTodayFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeTodayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ChallengeTodayTodayStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'success')
  success(r'success'),
  @JsonValue(r'failed')
  failed(r'failed');

  const ChallengeTodayTodayStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
