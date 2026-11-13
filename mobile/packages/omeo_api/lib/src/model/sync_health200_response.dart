//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/merge_suggestion.dart';
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_health200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SyncHealth200Response {
  /// Returns a new [SyncHealth200Response] instance.
  SyncHealth200Response({
    required this.days,

    required this.mergeSuggestions,

    required this.rewards,

    required this.lastSyncAt,
  });

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<DaySummary> days;

  @JsonKey(name: r'merge_suggestions', required: true, includeIfNull: false)
  final List<MergeSuggestion> mergeSuggestions;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @JsonKey(name: r'last_sync_at', required: true, includeIfNull: false)
  final DateTime lastSyncAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncHealth200Response &&
          other.days == days &&
          other.mergeSuggestions == mergeSuggestions &&
          other.rewards == rewards &&
          other.lastSyncAt == lastSyncAt;

  @override
  int get hashCode =>
      days.hashCode +
      mergeSuggestions.hashCode +
      rewards.hashCode +
      lastSyncAt.hashCode;

  factory SyncHealth200Response.fromJson(Map<String, dynamic> json) =>
      _$SyncHealth200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SyncHealth200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
