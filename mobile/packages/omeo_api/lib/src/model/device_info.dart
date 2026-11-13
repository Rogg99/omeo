//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceInfo {
  /// Returns a new [DeviceInfo] instance.
  DeviceInfo({this.name, this.platform, this.appVersion, this.fingerprint});

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @JsonKey(name: r'platform', required: false, includeIfNull: false)
  final DeviceInfoPlatformEnum? platform;

  @JsonKey(name: r'app_version', required: false, includeIfNull: false)
  final String? appVersion;

  /// Empreinte hachée (anti-fraude parrainage)
  @JsonKey(name: r'fingerprint', required: false, includeIfNull: false)
  final String? fingerprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          other.name == name &&
          other.platform == platform &&
          other.appVersion == appVersion &&
          other.fingerprint == fingerprint;

  @override
  int get hashCode =>
      name.hashCode +
      platform.hashCode +
      appVersion.hashCode +
      fingerprint.hashCode;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DeviceInfoPlatformEnum {
  @JsonValue(r'android')
  android(r'android'),
  @JsonValue(r'ios')
  ios(r'ios'),
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'admin')
  admin(r'admin');

  const DeviceInfoPlatformEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
