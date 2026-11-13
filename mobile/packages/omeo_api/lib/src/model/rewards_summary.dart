//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/level_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rewards_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RewardsSummary {
  /// Returns a new [RewardsSummary] instance.
  RewardsSummary({
    required this.level,

    required this.totalPoints,

    required this.streak,

    this.progressToNextPercent,
  });

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final LevelInfo level;

  @JsonKey(name: r'total_points', required: true, includeIfNull: false)
  final int totalPoints;

  @JsonKey(name: r'streak', required: true, includeIfNull: false)
  final int streak;

  @JsonKey(
    name: r'progress_to_next_percent',
    required: false,
    includeIfNull: false,
  )
  final int? progressToNextPercent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardsSummary &&
          other.level == level &&
          other.totalPoints == totalPoints &&
          other.streak == streak &&
          other.progressToNextPercent == progressToNextPercent;

  @override
  int get hashCode =>
      level.hashCode +
      totalPoints.hashCode +
      streak.hashCode +
      progressToNextPercent.hashCode;

  factory RewardsSummary.fromJson(Map<String, dynamic> json) =>
      _$RewardsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$RewardsSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
