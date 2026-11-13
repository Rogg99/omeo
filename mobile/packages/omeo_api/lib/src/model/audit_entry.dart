//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditEntry {
  /// Returns a new [AuditEntry] instance.
  AuditEntry({
    required this.id,

    this.actor,

    required this.action,

    this.targetType,

    this.targetId,

    this.before,

    this.after,

    this.ip,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'actor', required: false, includeIfNull: false)
  final String? actor;

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'target_type', required: false, includeIfNull: false)
  final String? targetType;

  @JsonKey(name: r'target_id', required: false, includeIfNull: false)
  final String? targetId;

  @JsonKey(name: r'before', required: false, includeIfNull: false)
  final Map<String, Object>? before;

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final Map<String, Object>? after;

  @JsonKey(name: r'ip', required: false, includeIfNull: false)
  final String? ip;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntry &&
          other.id == id &&
          other.actor == actor &&
          other.action == action &&
          other.targetType == targetType &&
          other.targetId == targetId &&
          other.before == before &&
          other.after == after &&
          other.ip == ip &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      (actor == null ? 0 : actor.hashCode) +
      action.hashCode +
      targetType.hashCode +
      targetId.hashCode +
      (before == null ? 0 : before.hashCode) +
      (after == null ? 0 : after.hashCode) +
      ip.hashCode +
      createdAt.hashCode;

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AuditEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
