//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_sync_input_workouts_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthSyncInputWorkoutsInner {
  /// Returns a new [HealthSyncInputWorkoutsInner] instance.
  HealthSyncInputWorkoutsInner({
    required this.externalId,

    required this.type,

    required this.startedAt,

    required this.durationS,

    this.kcal,

    this.distanceM,

    this.avgHr,
  });

  @JsonKey(name: r'external_id', required: true, includeIfNull: false)
  final String externalId;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  @JsonKey(name: r'started_at', required: true, includeIfNull: false)
  final DateTime startedAt;

  // minimum: 1
  @JsonKey(name: r'duration_s', required: true, includeIfNull: false)
  final int durationS;

  // minimum: 0
  @JsonKey(name: r'kcal', required: false, includeIfNull: false)
  final int? kcal;

  @JsonKey(name: r'distance_m', required: false, includeIfNull: false)
  final int? distanceM;

  @JsonKey(name: r'avg_hr', required: false, includeIfNull: false)
  final int? avgHr;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncInputWorkoutsInner &&
          other.externalId == externalId &&
          other.type == type &&
          other.startedAt == startedAt &&
          other.durationS == durationS &&
          other.kcal == kcal &&
          other.distanceM == distanceM &&
          other.avgHr == avgHr;

  @override
  int get hashCode =>
      externalId.hashCode +
      type.hashCode +
      startedAt.hashCode +
      durationS.hashCode +
      kcal.hashCode +
      distanceM.hashCode +
      avgHr.hashCode;

  factory HealthSyncInputWorkoutsInner.fromJson(Map<String, dynamic> json) =>
      _$HealthSyncInputWorkoutsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$HealthSyncInputWorkoutsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
