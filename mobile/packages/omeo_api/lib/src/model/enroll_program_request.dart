//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enroll_program_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrollProgramRequest {
  /// Returns a new [EnrollProgramRequest] instance.
  EnrollProgramRequest({this.replace = false});

  @JsonKey(
    defaultValue: false,
    name: r'replace',
    required: false,
    includeIfNull: false,
  )
  final bool? replace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollProgramRequest && other.replace == replace;

  @override
  int get hashCode => replace.hashCode;

  factory EnrollProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$EnrollProgramRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollProgramRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
