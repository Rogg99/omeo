//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_program_task_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckProgramTaskRequest {
  /// Returns a new [CheckProgramTaskRequest] instance.
  CheckProgramTaskRequest({required this.done, this.date});

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckProgramTaskRequest &&
          other.done == done &&
          other.date == date;

  @override
  int get hashCode => done.hashCode + date.hashCode;

  factory CheckProgramTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckProgramTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckProgramTaskRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
