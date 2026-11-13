//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'program_day_view_tasks_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgramDayViewTasksInner {
  /// Returns a new [ProgramDayViewTasksInner] instance.
  ProgramDayViewTasksInner({
    required this.id,

    required this.label,

    required this.done,

    required this.validation,

    this.progress,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  @JsonKey(name: r'validation', required: true, includeIfNull: false)
  final ProgramDayViewTasksInnerValidationEnum validation;

  /// 0-1 pour les tâches automatiques
  @JsonKey(name: r'progress', required: false, includeIfNull: false)
  final num? progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDayViewTasksInner &&
          other.id == id &&
          other.label == label &&
          other.done == done &&
          other.validation == validation &&
          other.progress == progress;

  @override
  int get hashCode =>
      id.hashCode +
      label.hashCode +
      done.hashCode +
      validation.hashCode +
      (progress == null ? 0 : progress.hashCode);

  factory ProgramDayViewTasksInner.fromJson(Map<String, dynamic> json) =>
      _$ProgramDayViewTasksInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDayViewTasksInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProgramDayViewTasksInnerValidationEnum {
  @JsonValue(r'auto')
  auto(r'auto'),
  @JsonValue(r'manual')
  manual(r'manual');

  const ProgramDayViewTasksInnerValidationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
