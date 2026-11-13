//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'logout_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoutRequest {
  /// Returns a new [LogoutRequest] instance.
  LogoutRequest({this.allDevices = false});

  @JsonKey(
    defaultValue: false,
    name: r'all_devices',
    required: false,
    includeIfNull: false,
  )
  final bool? allDevices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogoutRequest && other.allDevices == allDevices;

  @override
  int get hashCode => allDevices.hashCode;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
