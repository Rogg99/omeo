//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/level.dart';
import 'package:omeo_api/src/model/workout_detail_all_of_steps.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workout_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkoutDetail {
  /// Returns a new [WorkoutDetail] instance.
  WorkoutDetail({
    required this.id,

    required this.name,

    required this.goal,

    required this.level,

    required this.durationS,

    this.exercisesCount,

    this.estimatedKcal,

    this.cover,

    required this.locked,

    this.description,

    this.downloadable,

    required this.steps,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final WorkoutDetailGoalEnum goal;

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

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'downloadable', required: false, includeIfNull: false)
  final bool? downloadable;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<WorkoutDetailAllOfSteps> steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDetail &&
          other.id == id &&
          other.name == name &&
          other.goal == goal &&
          other.level == level &&
          other.durationS == durationS &&
          other.exercisesCount == exercisesCount &&
          other.estimatedKcal == estimatedKcal &&
          other.cover == cover &&
          other.locked == locked &&
          other.description == description &&
          other.downloadable == downloadable &&
          other.steps == steps;

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
      locked.hashCode +
      description.hashCode +
      downloadable.hashCode +
      steps.hashCode;

  factory WorkoutDetail.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDetailFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WorkoutDetailGoalEnum {
  @JsonValue(r'cardio')
  cardio(r'cardio'),
  @JsonValue(r'strength')
  strength(r'strength'),
  @JsonValue(r'mobility')
  mobility(r'mobility');

  const WorkoutDetailGoalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
