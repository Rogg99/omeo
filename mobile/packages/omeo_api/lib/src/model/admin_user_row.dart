//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/plan_tier.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserRow {
  /// Returns a new [AdminUserRow] instance.
  AdminUserRow({
    required this.id,

    required this.email,

    required this.name,

    this.country,

    this.locale,

    required this.tier,

    required this.status,

    this.platform,

    this.lastSeenAt,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final PlanTier tier;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdminUserRowStatusEnum status;

  @JsonKey(name: r'platform', required: false, includeIfNull: false)
  final String? platform;

  @JsonKey(name: r'last_seen_at', required: false, includeIfNull: false)
  final DateTime? lastSeenAt;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserRow &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.country == country &&
          other.locale == locale &&
          other.tier == tier &&
          other.status == status &&
          other.platform == platform &&
          other.lastSeenAt == lastSeenAt &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      email.hashCode +
      name.hashCode +
      (country == null ? 0 : country.hashCode) +
      locale.hashCode +
      tier.hashCode +
      status.hashCode +
      (platform == null ? 0 : platform.hashCode) +
      (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
      createdAt.hashCode;

  factory AdminUserRow.fromJson(Map<String, dynamic> json) =>
      _$AdminUserRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminUserRowStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'suspended')
  suspended(r'suspended'),
  @JsonValue(r'deletion_pending')
  deletionPending(r'deletion_pending');

  const AdminUserRowStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
