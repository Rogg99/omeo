//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:omeo_api/src/model/ticket_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_update_ticket_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUpdateTicketRequest {
  /// Returns a new [AdminUpdateTicketRequest] instance.
  AdminUpdateTicketRequest({
    this.status,

    this.assigneeId,

    this.priority,

    this.category,
  });

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final TicketStatus? status;

  @JsonKey(name: r'assignee_id', required: false, includeIfNull: false)
  final String? assigneeId;

  @JsonKey(name: r'priority', required: false, includeIfNull: false)
  final AdminUpdateTicketRequestPriorityEnum? priority;

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final TicketCategory? category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUpdateTicketRequest &&
          other.status == status &&
          other.assigneeId == assigneeId &&
          other.priority == priority &&
          other.category == category;

  @override
  int get hashCode =>
      status.hashCode +
      (assigneeId == null ? 0 : assigneeId.hashCode) +
      priority.hashCode +
      category.hashCode;

  factory AdminUpdateTicketRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminUpdateTicketRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUpdateTicketRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminUpdateTicketRequestPriorityEnum {
  @JsonValue(r'low')
  low(r'low'),
  @JsonValue(r'normal')
  normal(r'normal'),
  @JsonValue(r'high')
  high(r'high');

  const AdminUpdateTicketRequestPriorityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
