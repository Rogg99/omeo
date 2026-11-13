//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config_min_version.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfigMinVersion {
  /// Returns a new [AppConfigMinVersion] instance.
  AppConfigMinVersion({this.android, this.ios});

  @JsonKey(name: r'android', required: false, includeIfNull: false)
  final String? android;

  @JsonKey(name: r'ios', required: false, includeIfNull: false)
  final String? ios;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigMinVersion &&
          other.android == android &&
          other.ios == ios;

  @override
  int get hashCode => android.hashCode + ios.hashCode;

  factory AppConfigMinVersion.fromJson(Map<String, dynamic> json) =>
      _$AppConfigMinVersionFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigMinVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
