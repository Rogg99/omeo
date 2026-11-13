//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityInput {
  /// Returns a new [ActivityInput] instance.
  ActivityInput({
    required this.type,

    required this.durationS,

    required this.intensity,

    this.startedAt,

    this.date,

    this.label,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ActivityInputTypeEnum type;

  // minimum: 60
  // maximum: 43200
  @JsonKey(name: r'duration_s', required: true, includeIfNull: false)
  final int durationS;

  @JsonKey(name: r'intensity', required: true, includeIfNull: false)
  final ActivityInputIntensityEnum intensity;

  @JsonKey(name: r'started_at', required: false, includeIfNull: false)
  final DateTime? startedAt;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityInput &&
          other.type == type &&
          other.durationS == durationS &&
          other.intensity == intensity &&
          other.startedAt == startedAt &&
          other.date == date &&
          other.label == label;

  @override
  int get hashCode =>
      type.hashCode +
      durationS.hashCode +
      intensity.hashCode +
      startedAt.hashCode +
      date.hashCode +
      label.hashCode;

  factory ActivityInput.fromJson(Map<String, dynamic> json) =>
      _$ActivityInputFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ActivityInputTypeEnum {
  @JsonValue(r'walking')
  walking(r'walking'),
  @JsonValue(r'running')
  running(r'running'),
  @JsonValue(r'football')
  football(r'football'),
  @JsonValue(r'dancing')
  dancing(r'dancing'),
  @JsonValue(r'cycling')
  cycling(r'cycling'),
  @JsonValue(r'strength')
  strength(r'strength'),
  @JsonValue(r'swimming')
  swimming(r'swimming'),
  @JsonValue(r'other')
  other(r'other');

  const ActivityInputTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ActivityInputIntensityEnum {
  @JsonValue(r'light')
  light(r'light'),
  @JsonValue(r'moderate')
  moderate(r'moderate'),
  @JsonValue(r'vigorous')
  vigorous(r'vigorous');

  const ActivityInputIntensityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
