//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/health_sync_input_days_inner.dart';
import 'package:omeo_api/src/model/health_sync_input_weights_inner.dart';
import 'package:omeo_api/src/model/health_sync_input_workouts_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_sync_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthSyncInput {
  /// Returns a new [HealthSyncInput] instance.
  HealthSyncInput({
    required this.source_,

    required this.days,

    this.workouts,

    this.weights,
  });

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final HealthSyncInputSource_Enum source_;

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<HealthSyncInputDaysInner> days;

  @JsonKey(name: r'workouts', required: false, includeIfNull: false)
  final List<HealthSyncInputWorkoutsInner>? workouts;

  @JsonKey(name: r'weights', required: false, includeIfNull: false)
  final List<HealthSyncInputWeightsInner>? weights;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncInput &&
          other.source_ == source_ &&
          other.days == days &&
          other.workouts == workouts &&
          other.weights == weights;

  @override
  int get hashCode =>
      source_.hashCode + days.hashCode + workouts.hashCode + weights.hashCode;

  factory HealthSyncInput.fromJson(Map<String, dynamic> json) =>
      _$HealthSyncInputFromJson(json);

  Map<String, dynamic> toJson() => _$HealthSyncInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthSyncInputSource_Enum {
  @JsonValue(r'health_connect')
  healthConnect(r'health_connect'),
  @JsonValue(r'apple_health')
  appleHealth(r'apple_health');

  const HealthSyncInputSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
