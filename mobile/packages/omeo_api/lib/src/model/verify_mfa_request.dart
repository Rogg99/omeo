//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verify_mfa_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerifyMfaRequest {
  /// Returns a new [VerifyMfaRequest] instance.
  VerifyMfaRequest({required this.mfaToken, required this.code});

  @JsonKey(name: r'mfa_token', required: true, includeIfNull: false)
  final String mfaToken;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifyMfaRequest &&
          other.mfaToken == mfaToken &&
          other.code == code;

  @override
  int get hashCode => mfaToken.hashCode + code.hashCode;

  factory VerifyMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyMfaRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
