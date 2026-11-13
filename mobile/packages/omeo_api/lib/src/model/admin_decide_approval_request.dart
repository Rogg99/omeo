//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_decide_approval_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDecideApprovalRequest {
  /// Returns a new [AdminDecideApprovalRequest] instance.
  AdminDecideApprovalRequest({required this.decision, this.comment});

  @JsonKey(name: r'decision', required: true, includeIfNull: false)
  final AdminDecideApprovalRequestDecisionEnum decision;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDecideApprovalRequest &&
          other.decision == decision &&
          other.comment == comment;

  @override
  int get hashCode => decision.hashCode + comment.hashCode;

  factory AdminDecideApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminDecideApprovalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDecideApprovalRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminDecideApprovalRequestDecisionEnum {
  @JsonValue(r'approve')
  approve(r'approve'),
  @JsonValue(r'reject')
  reject(r'reject');

  const AdminDecideApprovalRequestDecisionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
