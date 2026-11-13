//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/staff_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_invite_staff_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminInviteStaffRequest {
  /// Returns a new [AdminInviteStaffRequest] instance.
  AdminInviteStaffRequest({required this.email, required this.roles});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<StaffRole> roles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminInviteStaffRequest &&
          other.email == email &&
          other.roles == roles;

  @override
  int get hashCode => email.hashCode + roles.hashCode;

  factory AdminInviteStaffRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminInviteStaffRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminInviteStaffRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
