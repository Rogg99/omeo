//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:omeo_api/src/model/ticket_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_ticket_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTicketRow {
  /// Returns a new [AdminTicketRow] instance.
  AdminTicketRow({
    required this.id,

    required this.number,

    required this.subject,

    this.category,

    required this.status,

    this.hasUnreadReply,

    required this.updatedAt,

    this.email,

    this.assignee,

    this.priority,

    this.channel,

    this.createdAt,
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

  @JsonKey(name: r'assignee', required: false, includeIfNull: false)
  final String? assignee;

  @JsonKey(name: r'priority', required: false, includeIfNull: false)
  final String? priority;

  @JsonKey(name: r'channel', required: false, includeIfNull: false)
  final AdminTicketRowChannelEnum? channel;

  @JsonKey(name: r'created_at', required: false, includeIfNull: false)
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminTicketRow &&
          other.id == id &&
          other.number == number &&
          other.subject == subject &&
          other.category == category &&
          other.status == status &&
          other.hasUnreadReply == hasUnreadReply &&
          other.updatedAt == updatedAt &&
          other.email == email &&
          other.assignee == assignee &&
          other.priority == priority &&
          other.channel == channel &&
          other.createdAt == createdAt;

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
      (assignee == null ? 0 : assignee.hashCode) +
      priority.hashCode +
      channel.hashCode +
      createdAt.hashCode;

  factory AdminTicketRow.fromJson(Map<String, dynamic> json) =>
      _$AdminTicketRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTicketRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminTicketRowChannelEnum {
  @JsonValue(r'app')
  app(r'app'),
  @JsonValue(r'web')
  web(r'web');

  const AdminTicketRowChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
