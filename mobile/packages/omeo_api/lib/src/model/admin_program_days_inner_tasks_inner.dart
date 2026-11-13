//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/rule_def.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_program_days_inner_tasks_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminProgramDaysInnerTasksInner {
  /// Returns a new [AdminProgramDaysInnerTasksInner] instance.
  AdminProgramDaysInnerTasksInner({required this.label, this.rule});

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final Map<String, String> label;

  @JsonKey(name: r'rule', required: false, includeIfNull: false)
  final RuleDef? rule;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProgramDaysInnerTasksInner &&
          other.label == label &&
          other.rule == rule;

  @override
  int get hashCode => label.hashCode + (rule == null ? 0 : rule.hashCode);

  factory AdminProgramDaysInnerTasksInner.fromJson(Map<String, dynamic> json) =>
      _$AdminProgramDaysInnerTasksInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminProgramDaysInnerTasksInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
