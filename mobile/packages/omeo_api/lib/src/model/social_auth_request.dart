//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/onboarding_profile.dart';
import 'package:omeo_api/src/model/device_info.dart';
import 'package:omeo_api/src/model/consent_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_auth_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SocialAuthRequest {
  /// Returns a new [SocialAuthRequest] instance.
  SocialAuthRequest({
    required this.provider,

    required this.idToken,

    this.nonce,

    this.inviteCode,

    this.profile,

    this.consents,

    this.device,
  });

  @JsonKey(name: r'provider', required: true, includeIfNull: false)
  final SocialAuthRequestProviderEnum provider;

  @JsonKey(name: r'id_token', required: true, includeIfNull: false)
  final String idToken;

  /// Apple
  @JsonKey(name: r'nonce', required: false, includeIfNull: false)
  final String? nonce;

  @JsonKey(name: r'invite_code', required: false, includeIfNull: false)
  final String? inviteCode;

  @JsonKey(name: r'profile', required: false, includeIfNull: false)
  final OnboardingProfile? profile;

  @JsonKey(name: r'consents', required: false, includeIfNull: false)
  final List<ConsentInput>? consents;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final DeviceInfo? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialAuthRequest &&
          other.provider == provider &&
          other.idToken == idToken &&
          other.nonce == nonce &&
          other.inviteCode == inviteCode &&
          other.profile == profile &&
          other.consents == consents &&
          other.device == device;

  @override
  int get hashCode =>
      provider.hashCode +
      idToken.hashCode +
      nonce.hashCode +
      inviteCode.hashCode +
      profile.hashCode +
      consents.hashCode +
      device.hashCode;

  factory SocialAuthRequest.fromJson(Map<String, dynamic> json) =>
      _$SocialAuthRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SocialAuthRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SocialAuthRequestProviderEnum {
  @JsonValue(r'google')
  google(r'google'),
  @JsonValue(r'apple')
  apple(r'apple');

  const SocialAuthRequestProviderEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
