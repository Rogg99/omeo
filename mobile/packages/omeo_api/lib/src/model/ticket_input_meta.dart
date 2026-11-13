//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_input_meta.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TicketInputMeta {
  /// Returns a new [TicketInputMeta] instance.
  TicketInputMeta({this.appVersion, this.os, this.device});

  @JsonKey(name: r'app_version', required: false, includeIfNull: false)
  final String? appVersion;

  @JsonKey(name: r'os', required: false, includeIfNull: false)
  final String? os;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final String? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketInputMeta &&
          other.appVersion == appVersion &&
          other.os == os &&
          other.device == device;

  @override
  int get hashCode => appVersion.hashCode + os.hashCode + device.hashCode;

  factory TicketInputMeta.fromJson(Map<String, dynamic> json) =>
      _$TicketInputMetaFromJson(json);

  Map<String, dynamic> toJson() => _$TicketInputMetaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
