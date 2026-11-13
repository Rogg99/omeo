//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_workout_steps_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminWorkoutStepsInner {
  /// Returns a new [AdminWorkoutStepsInner] instance.
  AdminWorkoutStepsInner({
    required this.exerciseId,

    required this.mode,

    this.durationS,

    this.reps,

    required this.restS,
  });

  @JsonKey(name: r'exercise_id', required: true, includeIfNull: false)
  final String exerciseId;

  @JsonKey(name: r'mode', required: true, includeIfNull: false)
  final AdminWorkoutStepsInnerModeEnum mode;

  @JsonKey(name: r'duration_s', required: false, includeIfNull: false)
  final int? durationS;

  @JsonKey(name: r'reps', required: false, includeIfNull: false)
  final int? reps;

  @JsonKey(name: r'rest_s', required: true, includeIfNull: false)
  final int restS;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminWorkoutStepsInner &&
          other.exerciseId == exerciseId &&
          other.mode == mode &&
          other.durationS == durationS &&
          other.reps == reps &&
          other.restS == restS;

  @override
  int get hashCode =>
      exerciseId.hashCode +
      mode.hashCode +
      durationS.hashCode +
      reps.hashCode +
      restS.hashCode;

  factory AdminWorkoutStepsInner.fromJson(Map<String, dynamic> json) =>
      _$AdminWorkoutStepsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminWorkoutStepsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminWorkoutStepsInnerModeEnum {
  @JsonValue(r'time')
  time(r'time'),
  @JsonValue(r'reps')
  reps(r'reps');

  const AdminWorkoutStepsInnerModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
