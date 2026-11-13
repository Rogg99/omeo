//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_program_days_inner_tasks_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_program_days_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminProgramDaysInner {
  /// Returns a new [AdminProgramDaysInner] instance.
  AdminProgramDaysInner({
    required this.dayIndex,

    this.tip,

    this.workoutId,

    this.recipeIds,

    this.tasks,
  });

  // minimum: 1
  @JsonKey(name: r'day_index', required: true, includeIfNull: false)
  final int dayIndex;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'tip', required: false, includeIfNull: false)
  final Map<String, String>? tip;

  @JsonKey(name: r'workout_id', required: false, includeIfNull: false)
  final String? workoutId;

  @JsonKey(name: r'recipe_ids', required: false, includeIfNull: false)
  final List<String>? recipeIds;

  @JsonKey(name: r'tasks', required: false, includeIfNull: false)
  final List<AdminProgramDaysInnerTasksInner>? tasks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProgramDaysInner &&
          other.dayIndex == dayIndex &&
          other.tip == tip &&
          other.workoutId == workoutId &&
          other.recipeIds == recipeIds &&
          other.tasks == tasks;

  @override
  int get hashCode =>
      dayIndex.hashCode +
      tip.hashCode +
      (workoutId == null ? 0 : workoutId.hashCode) +
      recipeIds.hashCode +
      tasks.hashCode;

  factory AdminProgramDaysInner.fromJson(Map<String, dynamic> json) =>
      _$AdminProgramDaysInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminProgramDaysInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
