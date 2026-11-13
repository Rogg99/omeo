//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/user_badge.dart';
import 'package:omeo_api/src/model/level_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rewards_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RewardsOverview {
  /// Returns a new [RewardsOverview] instance.
  RewardsOverview({
    required this.level,

    required this.nextLevel,

    required this.totalPoints,

    required this.pointsToNext,

    required this.progressPercent,

    required this.weekPoints,

    required this.streak,

    required this.bestStreak,

    this.streakFreezeAvailable,

    required this.badgesEarned,

    required this.badgesNext,
  });

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final LevelInfo level;

  @JsonKey(name: r'next_level', required: true, includeIfNull: true)
  final LevelInfo? nextLevel;

  @JsonKey(name: r'total_points', required: true, includeIfNull: false)
  final int totalPoints;

  @JsonKey(name: r'points_to_next', required: true, includeIfNull: false)
  final int pointsToNext;

  @JsonKey(name: r'progress_percent', required: true, includeIfNull: false)
  final int progressPercent;

  @JsonKey(name: r'week_points', required: true, includeIfNull: false)
  final int weekPoints;

  @JsonKey(name: r'streak', required: true, includeIfNull: false)
  final int streak;

  @JsonKey(name: r'best_streak', required: true, includeIfNull: false)
  final int bestStreak;

  @JsonKey(
    name: r'streak_freeze_available',
    required: false,
    includeIfNull: false,
  )
  final bool? streakFreezeAvailable;

  @JsonKey(name: r'badges_earned', required: true, includeIfNull: false)
  final List<UserBadge> badgesEarned;

  @JsonKey(name: r'badges_next', required: true, includeIfNull: false)
  final List<UserBadge> badgesNext;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardsOverview &&
          other.level == level &&
          other.nextLevel == nextLevel &&
          other.totalPoints == totalPoints &&
          other.pointsToNext == pointsToNext &&
          other.progressPercent == progressPercent &&
          other.weekPoints == weekPoints &&
          other.streak == streak &&
          other.bestStreak == bestStreak &&
          other.streakFreezeAvailable == streakFreezeAvailable &&
          other.badgesEarned == badgesEarned &&
          other.badgesNext == badgesNext;

  @override
  int get hashCode =>
      level.hashCode +
      (nextLevel == null ? 0 : nextLevel.hashCode) +
      totalPoints.hashCode +
      pointsToNext.hashCode +
      progressPercent.hashCode +
      weekPoints.hashCode +
      streak.hashCode +
      bestStreak.hashCode +
      streakFreezeAvailable.hashCode +
      badgesEarned.hashCode +
      badgesNext.hashCode;

  factory RewardsOverview.fromJson(Map<String, dynamic> json) =>
      _$RewardsOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$RewardsOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
