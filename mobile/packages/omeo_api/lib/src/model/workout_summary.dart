//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/level.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workout_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkoutSummary {
  /// Returns a new [WorkoutSummary] instance.
  WorkoutSummary({
    required this.id,

    required this.name,

    required this.goal,

    required this.level,

    required this.durationS,

    this.exercisesCount,

    this.estimatedKcal,

    this.cover,

    required this.locked,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final WorkoutSummaryGoalEnum goal;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final Level level;

  @JsonKey(name: r'duration_s', required: true, includeIfNull: false)
  final int durationS;

  @JsonKey(name: r'exercises_count', required: false, includeIfNull: false)
  final int? exercisesCount;

  @JsonKey(name: r'estimated_kcal', required: false, includeIfNull: false)
  final int? estimatedKcal;

  @JsonKey(name: r'cover', required: false, includeIfNull: false)
  final Image? cover;

  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSummary &&
          other.id == id &&
          other.name == name &&
          other.goal == goal &&
          other.level == level &&
          other.durationS == durationS &&
          other.exercisesCount == exercisesCount &&
          other.estimatedKcal == estimatedKcal &&
          other.cover == cover &&
          other.locked == locked;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      goal.hashCode +
      level.hashCode +
      durationS.hashCode +
      exercisesCount.hashCode +
      estimatedKcal.hashCode +
      cover.hashCode +
      locked.hashCode;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WorkoutSummaryGoalEnum {
  @JsonValue(r'cardio')
  cardio(r'cardio'),
  @JsonValue(r'strength')
  strength(r'strength'),
  @JsonValue(r'mobility')
  mobility(r'mobility');

  const WorkoutSummaryGoalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
