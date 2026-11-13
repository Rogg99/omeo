//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_invite_code_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckInviteCodeRequest {
  /// Returns a new [CheckInviteCodeRequest] instance.
  CheckInviteCodeRequest({required this.code});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInviteCodeRequest && other.code == code;

  @override
  int get hashCode => code.hashCode;

  factory CheckInviteCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckInviteCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInviteCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
