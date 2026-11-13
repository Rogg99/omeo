//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:omeo_api/src/model/ticket_detail_all_of_messages.dart';
import 'package:omeo_api/src/model/ticket_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TicketDetail {
  /// Returns a new [TicketDetail] instance.
  TicketDetail({
    required this.id,

    required this.number,

    required this.subject,

    this.category,

    required this.status,

    this.hasUnreadReply,

    required this.updatedAt,

    this.email,

    this.userId,

    this.assignee,

    this.priority,

    this.meta,

    required this.messages,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'subject', required: true, includeIfNull: false)
  final String subject;

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final TicketCategory? category;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TicketStatus status;

  @JsonKey(name: r'has_unread_reply', required: false, includeIfNull: false)
  final bool? hasUnreadReply;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final DateTime updatedAt;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'user_id', required: false, includeIfNull: false)
  final String? userId;

  @JsonKey(name: r'assignee', required: false, includeIfNull: false)
  final String? assignee;

  @JsonKey(name: r'priority', required: false, includeIfNull: false)
  final String? priority;

  @JsonKey(name: r'meta', required: false, includeIfNull: false)
  final Map<String, Object>? meta;

  @JsonKey(name: r'messages', required: true, includeIfNull: false)
  final List<TicketDetailAllOfMessages> messages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketDetail &&
          other.id == id &&
          other.number == number &&
          other.subject == subject &&
          other.category == category &&
          other.status == status &&
          other.hasUnreadReply == hasUnreadReply &&
          other.updatedAt == updatedAt &&
          other.email == email &&
          other.userId == userId &&
          other.assignee == assignee &&
          other.priority == priority &&
          other.meta == meta &&
          other.messages == messages;

  @override
  int get hashCode =>
      id.hashCode +
      number.hashCode +
      subject.hashCode +
      category.hashCode +
      status.hashCode +
      hasUnreadReply.hashCode +
      updatedAt.hashCode +
      email.hashCode +
      (userId == null ? 0 : userId.hashCode) +
      (assignee == null ? 0 : assignee.hashCode) +
      priority.hashCode +
      meta.hashCode +
      messages.hashCode;

  factory TicketDetail.fromJson(Map<String, dynamic> json) =>
      _$TicketDetailFromJson(json);

  Map<String, dynamic> toJson() => _$TicketDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
