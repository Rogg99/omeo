//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovalRequest {
  /// Returns a new [ApprovalRequest] instance.
  ApprovalRequest({
    required this.id,

    required this.kind,

    required this.domain,

    required this.status,

    required this.summary,

    this.targetType,

    this.targetId,

    this.diff,

    this.reason,

    required this.requestedBy,

    this.decidedBy,

    this.decisionComment,

    required this.createdAt,

    this.decidedAt,

    required this.expiresAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final ApprovalRequestKindEnum kind;

  @JsonKey(name: r'domain', required: true, includeIfNull: false)
  final ApprovalRequestDomainEnum domain;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ApprovalRequestStatusEnum status;

  /// Résumé lisible de l'action demandée
  @JsonKey(name: r'summary', required: true, includeIfNull: false)
  final String summary;

  @JsonKey(name: r'target_type', required: false, includeIfNull: false)
  final String? targetType;

  @JsonKey(name: r'target_id', required: false, includeIfNull: false)
  final String? targetId;

  /// Avant / après proposés
  @JsonKey(name: r'diff', required: false, includeIfNull: false)
  final Map<String, Object>? diff;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @JsonKey(name: r'requested_by', required: true, includeIfNull: false)
  final String requestedBy;

  @JsonKey(name: r'decided_by', required: false, includeIfNull: false)
  final String? decidedBy;

  @JsonKey(name: r'decision_comment', required: false, includeIfNull: false)
  final String? decisionComment;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'decided_at', required: false, includeIfNull: false)
  final DateTime? decidedAt;

  @JsonKey(name: r'expires_at', required: true, includeIfNull: false)
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalRequest &&
          other.id == id &&
          other.kind == kind &&
          other.domain == domain &&
          other.status == status &&
          other.summary == summary &&
          other.targetType == targetType &&
          other.targetId == targetId &&
          other.diff == diff &&
          other.reason == reason &&
          other.requestedBy == requestedBy &&
          other.decidedBy == decidedBy &&
          other.decisionComment == decisionComment &&
          other.createdAt == createdAt &&
          other.decidedAt == decidedAt &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      id.hashCode +
      kind.hashCode +
      domain.hashCode +
      status.hashCode +
      summary.hashCode +
      targetType.hashCode +
      targetId.hashCode +
      diff.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      requestedBy.hashCode +
      (decidedBy == null ? 0 : decidedBy.hashCode) +
      (decisionComment == null ? 0 : decisionComment.hashCode) +
      createdAt.hashCode +
      (decidedAt == null ? 0 : decidedAt.hashCode) +
      expiresAt.hashCode;

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ApprovalRequestKindEnum {
  @JsonValue(r'content_publish')
  contentPublish(r'content_publish'),
  @JsonValue(r'campaign_schedule')
  campaignSchedule(r'campaign_schedule'),
  @JsonValue(r'plan_update')
  planUpdate(r'plan_update'),
  @JsonValue(r'quota_update')
  quotaUpdate(r'quota_update'),
  @JsonValue(r'refund')
  refund(r'refund'),
  @JsonValue(r'settings_nutrition')
  settingsNutrition(r'settings_nutrition');

  const ApprovalRequestKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ApprovalRequestDomainEnum {
  @JsonValue(r'content')
  content(r'content'),
  @JsonValue(r'finance')
  finance(r'finance'),
  @JsonValue(r'settings')
  settings(r'settings');

  const ApprovalRequestDomainEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ApprovalRequestStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'rejected')
  rejected(r'rejected'),
  @JsonValue(r'expired')
  expired(r'expired'),
  @JsonValue(r'canceled')
  canceled(r'canceled');

  const ApprovalRequestStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
