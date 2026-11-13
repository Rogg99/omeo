//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/staff_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_update_staff_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUpdateStaffRequest {
  /// Returns a new [AdminUpdateStaffRequest] instance.
  AdminUpdateStaffRequest({this.roles, this.active, this.resetMfa});

  @JsonKey(name: r'roles', required: false, includeIfNull: false)
  final List<StaffRole>? roles;

  @JsonKey(name: r'active', required: false, includeIfNull: false)
  final bool? active;

  @JsonKey(name: r'reset_mfa', required: false, includeIfNull: false)
  final bool? resetMfa;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUpdateStaffRequest &&
          other.roles == roles &&
          other.active == active &&
          other.resetMfa == resetMfa;

  @override
  int get hashCode => roles.hashCode + active.hashCode + resetMfa.hashCode;

  factory AdminUpdateStaffRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminUpdateStaffRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUpdateStaffRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
