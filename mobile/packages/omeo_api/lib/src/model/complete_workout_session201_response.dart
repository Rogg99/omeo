//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'complete_workout_session201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompleteWorkoutSession201Response {
  /// Returns a new [CompleteWorkoutSession201Response] instance.
  CompleteWorkoutSession201Response({
    required this.id,

    required this.kcal,

    required this.durationS,

    required this.completed,

    required this.day,

    required this.rewards,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'duration_s', required: true, includeIfNull: false)
  final int durationS;

  @JsonKey(name: r'completed', required: true, includeIfNull: false)
  final bool completed;

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompleteWorkoutSession201Response &&
          other.id == id &&
          other.kcal == kcal &&
          other.durationS == durationS &&
          other.completed == completed &&
          other.day == day &&
          other.rewards == rewards;

  @override
  int get hashCode =>
      id.hashCode +
      kcal.hashCode +
      durationS.hashCode +
      completed.hashCode +
      day.hashCode +
      rewards.hashCode;

  factory CompleteWorkoutSession201Response.fromJson(
    Map<String, dynamic> json,
  ) => _$CompleteWorkoutSession201ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CompleteWorkoutSession201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
