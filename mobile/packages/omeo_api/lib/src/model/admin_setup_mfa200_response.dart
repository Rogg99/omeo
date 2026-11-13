//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_setup_mfa200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSetupMfa200Response {
  /// Returns a new [AdminSetupMfa200Response] instance.
  AdminSetupMfa200Response({
    this.otpauthUri,

    this.recoveryCodes,

    this.confirmed,
  });

  @JsonKey(name: r'otpauth_uri', required: false, includeIfNull: false)
  final String? otpauthUri;

  @JsonKey(name: r'recovery_codes', required: false, includeIfNull: false)
  final List<String>? recoveryCodes;

  @JsonKey(name: r'confirmed', required: false, includeIfNull: false)
  final bool? confirmed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSetupMfa200Response &&
          other.otpauthUri == otpauthUri &&
          other.recoveryCodes == recoveryCodes &&
          other.confirmed == confirmed;

  @override
  int get hashCode =>
      otpauthUri.hashCode + recoveryCodes.hashCode + confirmed.hashCode;

  factory AdminSetupMfa200Response.fromJson(Map<String, dynamic> json) =>
      _$AdminSetupMfa200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSetupMfa200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
