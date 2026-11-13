//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:omeo_api/src/model/ticket_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TicketSummary {
  /// Returns a new [TicketSummary] instance.
  TicketSummary({
    required this.id,

    required this.number,

    required this.subject,

    this.category,

    required this.status,

    this.hasUnreadReply,

    required this.updatedAt,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSummary &&
          other.id == id &&
          other.number == number &&
          other.subject == subject &&
          other.category == category &&
          other.status == status &&
          other.hasUnreadReply == hasUnreadReply &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      number.hashCode +
      subject.hashCode +
      category.hashCode +
      status.hashCode +
      hasUnreadReply.hashCode +
      updatedAt.hashCode;

  factory TicketSummary.fromJson(Map<String, dynamic> json) =>
      _$TicketSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$TicketSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
