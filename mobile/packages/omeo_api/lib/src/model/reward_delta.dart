//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/level_info.dart';
import 'package:omeo_api/src/model/badge_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reward_delta.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RewardDelta {
  /// Returns a new [RewardDelta] instance.
  RewardDelta({
    required this.points,

    this.totalPoints,

    this.levelUp,

    this.badges,

    this.streak,
  });

  @JsonKey(name: r'points', required: true, includeIfNull: false)
  final int points;

  @JsonKey(name: r'total_points', required: false, includeIfNull: false)
  final int? totalPoints;

  @JsonKey(name: r'level_up', required: false, includeIfNull: false)
  final LevelInfo? levelUp;

  @JsonKey(name: r'badges', required: false, includeIfNull: false)
  final List<BadgeRef>? badges;

  @JsonKey(name: r'streak', required: false, includeIfNull: false)
  final int? streak;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardDelta &&
          other.points == points &&
          other.totalPoints == totalPoints &&
          other.levelUp == levelUp &&
          other.badges == badges &&
          other.streak == streak;

  @override
  int get hashCode =>
      points.hashCode +
      totalPoints.hashCode +
      (levelUp == null ? 0 : levelUp.hashCode) +
      badges.hashCode +
      streak.hashCode;

  factory RewardDelta.fromJson(Map<String, dynamic> json) =>
      _$RewardDeltaFromJson(json);

  Map<String, dynamic> toJson() => _$RewardDeltaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
