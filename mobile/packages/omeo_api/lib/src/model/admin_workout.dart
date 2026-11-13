//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/level.dart';
import 'package:omeo_api/src/model/admin_workout_steps_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_workout.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminWorkout {
  /// Returns a new [AdminWorkout] instance.
  AdminWorkout({
    required this.name,

    this.description,

    required this.goal,

    required this.level,

    this.isFree,

    this.coverUploadId,

    required this.steps,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final Map<String, String> name;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final Map<String, String>? description;

  @JsonKey(name: r'goal', required: true, includeIfNull: false)
  final AdminWorkoutGoalEnum goal;

  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final Level level;

  @JsonKey(name: r'is_free', required: false, includeIfNull: false)
  final bool? isFree;

  @JsonKey(name: r'cover_upload_id', required: false, includeIfNull: false)
  final String? coverUploadId;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<AdminWorkoutStepsInner> steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminWorkout &&
          other.name == name &&
          other.description == description &&
          other.goal == goal &&
          other.level == level &&
          other.isFree == isFree &&
          other.coverUploadId == coverUploadId &&
          other.steps == steps;

  @override
  int get hashCode =>
      name.hashCode +
      description.hashCode +
      goal.hashCode +
      level.hashCode +
      isFree.hashCode +
      coverUploadId.hashCode +
      steps.hashCode;

  factory AdminWorkout.fromJson(Map<String, dynamic> json) =>
      _$AdminWorkoutFromJson(json);

  Map<String, dynamic> toJson() => _$AdminWorkoutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminWorkoutGoalEnum {
  @JsonValue(r'cardio')
  cardio(r'cardio'),
  @JsonValue(r'strength')
  strength(r'strength'),
  @JsonValue(r'mobility')
  mobility(r'mobility');

  const AdminWorkoutGoalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
