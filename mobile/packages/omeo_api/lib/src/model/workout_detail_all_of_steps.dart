//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/exercise_detail.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workout_detail_all_of_steps.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkoutDetailAllOfSteps {
  /// Returns a new [WorkoutDetailAllOfSteps] instance.
  WorkoutDetailAllOfSteps({
    required this.order,

    required this.exercise,

    required this.mode,

    this.durationS,

    this.reps,

    required this.restS,
  });

  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final int order;

  @JsonKey(name: r'exercise', required: true, includeIfNull: false)
  final ExerciseDetail exercise;

  @JsonKey(name: r'mode', required: true, includeIfNull: false)
  final WorkoutDetailAllOfStepsModeEnum mode;

  @JsonKey(name: r'duration_s', required: false, includeIfNull: false)
  final int? durationS;

  @JsonKey(name: r'reps', required: false, includeIfNull: false)
  final int? reps;

  @JsonKey(name: r'rest_s', required: true, includeIfNull: false)
  final int restS;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDetailAllOfSteps &&
          other.order == order &&
          other.exercise == exercise &&
          other.mode == mode &&
          other.durationS == durationS &&
          other.reps == reps &&
          other.restS == restS;

  @override
  int get hashCode =>
      order.hashCode +
      exercise.hashCode +
      mode.hashCode +
      (durationS == null ? 0 : durationS.hashCode) +
      (reps == null ? 0 : reps.hashCode) +
      restS.hashCode;

  factory WorkoutDetailAllOfSteps.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDetailAllOfStepsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutDetailAllOfStepsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WorkoutDetailAllOfStepsModeEnum {
  @JsonValue(r'time')
  time(r'time'),
  @JsonValue(r'reps')
  reps(r'reps');

  const WorkoutDetailAllOfStepsModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
