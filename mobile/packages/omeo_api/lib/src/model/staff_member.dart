//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/staff_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'staff_member.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StaffMember {
  /// Returns a new [StaffMember] instance.
  StaffMember({
    required this.id,

    required this.email,

    this.name,

    required this.roles,

    this.permissions,

    this.mfaVerifiedUntil,

    this.pendingApprovals,

    required this.mfaEnabled,

    required this.active,

    this.lastLoginAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<StaffRole> roles;

  /// Permissions effectives (docs/technique/controle-acces.md), ex. users.view, billing.refund
  @JsonKey(name: r'permissions', required: false, includeIfNull: false)
  final List<String>? permissions;

  /// Fin de validité du step-up
  @JsonKey(name: r'mfa_verified_until', required: false, includeIfNull: false)
  final DateTime? mfaVerifiedUntil;

  /// Demandes en attente que la personne peut valider
  @JsonKey(name: r'pending_approvals', required: false, includeIfNull: false)
  final int? pendingApprovals;

  @JsonKey(name: r'mfa_enabled', required: true, includeIfNull: false)
  final bool mfaEnabled;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'last_login_at', required: false, includeIfNull: false)
  final DateTime? lastLoginAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMember &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.roles == roles &&
          other.permissions == permissions &&
          other.mfaVerifiedUntil == mfaVerifiedUntil &&
          other.pendingApprovals == pendingApprovals &&
          other.mfaEnabled == mfaEnabled &&
          other.active == active &&
          other.lastLoginAt == lastLoginAt;

  @override
  int get hashCode =>
      id.hashCode +
      email.hashCode +
      name.hashCode +
      roles.hashCode +
      permissions.hashCode +
      (mfaVerifiedUntil == null ? 0 : mfaVerifiedUntil.hashCode) +
      pendingApprovals.hashCode +
      mfaEnabled.hashCode +
      active.hashCode +
      (lastLoginAt == null ? 0 : lastLoginAt.hashCode);

  factory StaffMember.fromJson(Map<String, dynamic> json) =>
      _$StaffMemberFromJson(json);

  Map<String, dynamic> toJson() => _$StaffMemberToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
