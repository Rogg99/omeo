//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_setup_mfa_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSetupMfaRequest {
  /// Returns a new [AdminSetupMfaRequest] instance.
  AdminSetupMfaRequest({this.code});

  /// Absent = génération ; présent = confirmation
  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final String? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSetupMfaRequest && other.code == code;

  @override
  int get hashCode => code.hashCode;

  factory AdminSetupMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminSetupMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSetupMfaRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
