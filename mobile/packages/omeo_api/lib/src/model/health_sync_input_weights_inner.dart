//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_sync_input_weights_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthSyncInputWeightsInner {
  /// Returns a new [HealthSyncInputWeightsInner] instance.
  HealthSyncInputWeightsInner({
    required this.measuredAt,

    required this.weightKg,
  });

  @JsonKey(name: r'measured_at', required: true, includeIfNull: false)
  final DateTime measuredAt;

  // minimum: 30
  // maximum: 300
  @JsonKey(name: r'weight_kg', required: true, includeIfNull: false)
  final num weightKg;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncInputWeightsInner &&
          other.measuredAt == measuredAt &&
          other.weightKg == weightKg;

  @override
  int get hashCode => measuredAt.hashCode + weightKg.hashCode;

  factory HealthSyncInputWeightsInner.fromJson(Map<String, dynamic> json) =>
      _$HealthSyncInputWeightsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$HealthSyncInputWeightsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
