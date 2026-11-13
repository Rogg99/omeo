//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/merge_suggestion.dart';
import 'package:omeo_api/src/model/activity.dart';
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_write_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityWriteResult {
  /// Returns a new [ActivityWriteResult] instance.
  ActivityWriteResult({
    required this.activity,

    required this.day,

    this.mergeSuggestion,

    required this.rewards,
  });

  @JsonKey(name: r'activity', required: true, includeIfNull: false)
  final Activity activity;

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  @JsonKey(name: r'merge_suggestion', required: false, includeIfNull: false)
  final MergeSuggestion? mergeSuggestion;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityWriteResult &&
          other.activity == activity &&
          other.day == day &&
          other.mergeSuggestion == mergeSuggestion &&
          other.rewards == rewards;

  @override
  int get hashCode =>
      activity.hashCode +
      day.hashCode +
      (mergeSuggestion == null ? 0 : mergeSuggestion.hashCode) +
      rewards.hashCode;

  factory ActivityWriteResult.fromJson(Map<String, dynamic> json) =>
      _$ActivityWriteResultFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityWriteResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
