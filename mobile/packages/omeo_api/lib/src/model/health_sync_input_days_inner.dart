//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_sync_input_days_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthSyncInputDaysInner {
  /// Returns a new [HealthSyncInputDaysInner] instance.
  HealthSyncInputDaysInner({
    required this.date,

    this.steps,

    this.distanceM,

    this.activeKcal,

    this.totalBurnedKcal,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  // minimum: 0
  // maximum: 200000
  @JsonKey(name: r'steps', required: false, includeIfNull: false)
  final int? steps;

  // minimum: 0
  @JsonKey(name: r'distance_m', required: false, includeIfNull: false)
  final int? distanceM;

  // minimum: 0
  // maximum: 20000
  @JsonKey(name: r'active_kcal', required: false, includeIfNull: false)
  final int? activeKcal;

  // minimum: 0
  @JsonKey(name: r'total_burned_kcal', required: false, includeIfNull: false)
  final int? totalBurnedKcal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncInputDaysInner &&
          other.date == date &&
          other.steps == steps &&
          other.distanceM == distanceM &&
          other.activeKcal == activeKcal &&
          other.totalBurnedKcal == totalBurnedKcal;

  @override
  int get hashCode =>
      date.hashCode +
      steps.hashCode +
      distanceM.hashCode +
      activeKcal.hashCode +
      totalBurnedKcal.hashCode;

  factory HealthSyncInputDaysInner.fromJson(Map<String, dynamic> json) =>
      _$HealthSyncInputDaysInnerFromJson(json);

  Map<String, dynamic> toJson() => _$HealthSyncInputDaysInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
