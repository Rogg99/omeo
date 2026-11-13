//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_four_eyes.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsFourEyes {
  /// Returns a new [SettingsFourEyes] instance.
  SettingsFourEyes({this.content, this.finance, this.settings});

  @JsonKey(name: r'content', required: false, includeIfNull: false)
  final bool? content;

  @JsonKey(name: r'finance', required: false, includeIfNull: false)
  final bool? finance;

  @JsonKey(name: r'settings', required: false, includeIfNull: false)
  final bool? settings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsFourEyes &&
          other.content == content &&
          other.finance == finance &&
          other.settings == settings;

  @override
  int get hashCode => content.hashCode + finance.hashCode + settings.hashCode;

  factory SettingsFourEyes.fromJson(Map<String, dynamic> json) =>
      _$SettingsFourEyesFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsFourEyesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
