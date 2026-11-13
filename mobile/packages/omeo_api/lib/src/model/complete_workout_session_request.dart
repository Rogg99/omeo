//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'complete_workout_session_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompleteWorkoutSessionRequest {
  /// Returns a new [CompleteWorkoutSessionRequest] instance.
  CompleteWorkoutSessionRequest({
    required this.workoutId,

    required this.startedAt,

    required this.endedAt,

    required this.completedSteps,
  });

  @JsonKey(name: r'workout_id', required: true, includeIfNull: false)
  final String workoutId;

  @JsonKey(name: r'started_at', required: true, includeIfNull: false)
  final DateTime startedAt;

  @JsonKey(name: r'ended_at', required: true, includeIfNull: false)
  final DateTime endedAt;

  // minimum: 0
  @JsonKey(name: r'completed_steps', required: true, includeIfNull: false)
  final int completedSteps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompleteWorkoutSessionRequest &&
          other.workoutId == workoutId &&
          other.startedAt == startedAt &&
          other.endedAt == endedAt &&
          other.completedSteps == completedSteps;

  @override
  int get hashCode =>
      workoutId.hashCode +
      startedAt.hashCode +
      endedAt.hashCode +
      completedSteps.hashCode;

  factory CompleteWorkoutSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteWorkoutSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteWorkoutSessionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
