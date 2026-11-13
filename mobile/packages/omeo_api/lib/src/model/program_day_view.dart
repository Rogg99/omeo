//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/program_day_view_tasks_inner.dart';
import 'package:omeo_api/src/model/recipe_summary.dart';
import 'package:omeo_api/src/model/workout_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_day_view.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramDayView {
  /// Returns a new [ProgramDayView] instance.
  ProgramDayView({
    required this.dayIndex,

    required this.date,

    this.tip,

    this.workout,

    this.suggestedRecipes,

    required this.tasks,

    this.status,
  });

  @JsonKey(name: r'day_index', required: true, includeIfNull: false)
  final int dayIndex;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'tip', required: false, includeIfNull: false)
  final String? tip;

  @JsonKey(name: r'workout', required: false, includeIfNull: false)
  final WorkoutSummary? workout;

  @JsonKey(name: r'suggested_recipes', required: false, includeIfNull: false)
  final List<RecipeSummary>? suggestedRecipes;

  @JsonKey(name: r'tasks', required: true, includeIfNull: false)
  final List<ProgramDayViewTasksInner> tasks;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final ProgramDayViewStatusEnum? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDayView &&
          other.dayIndex == dayIndex &&
          other.date == date &&
          other.tip == tip &&
          other.workout == workout &&
          other.suggestedRecipes == suggestedRecipes &&
          other.tasks == tasks &&
          other.status == status;

  @override
  int get hashCode =>
      dayIndex.hashCode +
      date.hashCode +
      (tip == null ? 0 : tip.hashCode) +
      (workout == null ? 0 : workout.hashCode) +
      suggestedRecipes.hashCode +
      tasks.hashCode +
      status.hashCode;

  factory ProgramDayView.fromJson(Map<String, dynamic> json) =>
      _$ProgramDayViewFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDayViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProgramDayViewStatusEnum {
  @JsonValue(r'done')
  done(r'done'),
  @JsonValue(r'partial')
  partial(r'partial'),
  @JsonValue(r'missed')
  missed(r'missed'),
  @JsonValue(r'today')
  today(r'today'),
  @JsonValue(r'upcoming')
  upcoming(r'upcoming');

  const ProgramDayViewStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
