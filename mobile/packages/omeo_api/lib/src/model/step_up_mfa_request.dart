//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'step_up_mfa_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StepUpMfaRequest {
  /// Returns a new [StepUpMfaRequest] instance.
  StepUpMfaRequest({required this.code});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StepUpMfaRequest && other.code == code;

  @override
  int get hashCode => code.hashCode;

  factory StepUpMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$StepUpMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StepUpMfaRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
