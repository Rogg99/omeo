//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_push_device_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RegisterPushDeviceRequest {
  /// Returns a new [RegisterPushDeviceRequest] instance.
  RegisterPushDeviceRequest({
    required this.token,

    required this.platform,

    this.appVersion,
  });

  @JsonKey(name: r'token', required: true, includeIfNull: false)
  final String token;

  @JsonKey(name: r'platform', required: true, includeIfNull: false)
  final RegisterPushDeviceRequestPlatformEnum platform;

  @JsonKey(name: r'app_version', required: false, includeIfNull: false)
  final String? appVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterPushDeviceRequest &&
          other.token == token &&
          other.platform == platform &&
          other.appVersion == appVersion;

  @override
  int get hashCode => token.hashCode + platform.hashCode + appVersion.hashCode;

  factory RegisterPushDeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPushDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterPushDeviceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RegisterPushDeviceRequestPlatformEnum {
  @JsonValue(r'android')
  android(r'android'),
  @JsonValue(r'ios')
  ios(r'ios');

  const RegisterPushDeviceRequestPlatformEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
