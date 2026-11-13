//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Activity {
  /// Returns a new [Activity] instance.
  Activity({
    required this.id,

    required this.date,

    required this.type,

    this.label,

    this.startedAt,

    required this.durationS,

    this.intensity,

    required this.kcal,

    this.distanceM,

    this.avgHr,

    required this.source_,

    required this.editable,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  @JsonKey(name: r'started_at', required: false, includeIfNull: false)
  final DateTime? startedAt;

  @JsonKey(name: r'duration_s', required: true, includeIfNull: false)
  final int durationS;

  @JsonKey(name: r'intensity', required: false, includeIfNull: false)
  final String? intensity;

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'distance_m', required: false, includeIfNull: false)
  final int? distanceM;

  @JsonKey(name: r'avg_hr', required: false, includeIfNull: false)
  final int? avgHr;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final ActivitySource_Enum source_;

  @JsonKey(name: r'editable', required: true, includeIfNull: false)
  final bool editable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          other.id == id &&
          other.date == date &&
          other.type == type &&
          other.label == label &&
          other.startedAt == startedAt &&
          other.durationS == durationS &&
          other.intensity == intensity &&
          other.kcal == kcal &&
          other.distanceM == distanceM &&
          other.avgHr == avgHr &&
          other.source_ == source_ &&
          other.editable == editable;

  @override
  int get hashCode =>
      id.hashCode +
      date.hashCode +
      type.hashCode +
      label.hashCode +
      startedAt.hashCode +
      durationS.hashCode +
      (intensity == null ? 0 : intensity.hashCode) +
      kcal.hashCode +
      (distanceM == null ? 0 : distanceM.hashCode) +
      (avgHr == null ? 0 : avgHr.hashCode) +
      source_.hashCode +
      editable.hashCode;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ActivitySource_Enum {
  @JsonValue(r'manual')
  manual(r'manual'),
  @JsonValue(r'health_connect')
  healthConnect(r'health_connect'),
  @JsonValue(r'apple_health')
  appleHealth(r'apple_health'),
  @JsonValue(r'workout')
  workout(r'workout');

  const ActivitySource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
