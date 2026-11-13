//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_today.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramToday {
  /// Returns a new [ProgramToday] instance.
  ProgramToday({
    required this.enrollmentId,

    required this.programName,

    required this.dayIndex,

    required this.totalDays,

    required this.percent,

    this.tasksDone,

    this.tasksTotal,
  });

  @JsonKey(name: r'enrollment_id', required: true, includeIfNull: false)
  final String enrollmentId;

  @JsonKey(name: r'program_name', required: true, includeIfNull: false)
  final String programName;

  @JsonKey(name: r'day_index', required: true, includeIfNull: false)
  final int dayIndex;

  @JsonKey(name: r'total_days', required: true, includeIfNull: false)
  final int totalDays;

  @JsonKey(name: r'percent', required: true, includeIfNull: false)
  final int percent;

  @JsonKey(name: r'tasks_done', required: false, includeIfNull: false)
  final int? tasksDone;

  @JsonKey(name: r'tasks_total', required: false, includeIfNull: false)
  final int? tasksTotal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramToday &&
          other.enrollmentId == enrollmentId &&
          other.programName == programName &&
          other.dayIndex == dayIndex &&
          other.totalDays == totalDays &&
          other.percent == percent &&
          other.tasksDone == tasksDone &&
          other.tasksTotal == tasksTotal;

  @override
  int get hashCode =>
      enrollmentId.hashCode +
      programName.hashCode +
      dayIndex.hashCode +
      totalDays.hashCode +
      percent.hashCode +
      tasksDone.hashCode +
      tasksTotal.hashCode;

  factory ProgramToday.fromJson(Map<String, dynamic> json) =>
      _$ProgramTodayFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramTodayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
