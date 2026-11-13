//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_password_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangePasswordRequest {
  /// Returns a new [ChangePasswordRequest] instance.
  ChangePasswordRequest({this.currentPassword, required this.newPassword});

  /// Absent si compte social sans mot de passe
  @JsonKey(name: r'current_password', required: false, includeIfNull: false)
  final String? currentPassword;

  /// ≥ 10 caractères, minuscule, majuscule, chiffre, caractère spécial (vérifié par l'API)
  @JsonKey(name: r'new_password', required: true, includeIfNull: false)
  final String newPassword;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangePasswordRequest &&
          other.currentPassword == currentPassword &&
          other.newPassword == newPassword;

  @override
  int get hashCode => currentPassword.hashCode + newPassword.hashCode;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
