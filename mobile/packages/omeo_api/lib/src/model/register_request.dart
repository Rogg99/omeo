//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/onboarding_profile.dart';
import 'package:omeo_api/src/model/device_info.dart';
import 'package:omeo_api/src/model/consent_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    required this.email,

    required this.password,

    this.inviteCode,

    required this.profile,

    required this.consents,

    this.device,
  });

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// ≥ 10 caractères, minuscule, majuscule, chiffre, caractère spécial (vérifié par l'API)
  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  @JsonKey(name: r'invite_code', required: false, includeIfNull: false)
  final String? inviteCode;

  @JsonKey(name: r'profile', required: true, includeIfNull: false)
  final OnboardingProfile profile;

  @JsonKey(name: r'consents', required: true, includeIfNull: false)
  final List<ConsentInput> consents;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final DeviceInfo? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterRequest &&
          other.email == email &&
          other.password == password &&
          other.inviteCode == inviteCode &&
          other.profile == profile &&
          other.consents == consents &&
          other.device == device;

  @override
  int get hashCode =>
      email.hashCode +
      password.hashCode +
      inviteCode.hashCode +
      profile.hashCode +
      consents.hashCode +
      device.hashCode;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
