//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'step_up_mfa200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StepUpMfa200Response {
  /// Returns a new [StepUpMfa200Response] instance.
  StepUpMfa200Response({required this.mfaVerifiedUntil});

  @JsonKey(name: r'mfa_verified_until', required: true, includeIfNull: false)
  final DateTime mfaVerifiedUntil;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepUpMfa200Response &&
          other.mfaVerifiedUntil == mfaVerifiedUntil;

  @override
  int get hashCode => mfaVerifiedUntil.hashCode;

  factory StepUpMfa200Response.fromJson(Map<String, dynamic> json) =>
      _$StepUpMfa200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StepUpMfa200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
