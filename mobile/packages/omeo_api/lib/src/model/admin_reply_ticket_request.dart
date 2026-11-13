//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_reply_ticket_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminReplyTicketRequest {
  /// Returns a new [AdminReplyTicketRequest] instance.
  AdminReplyTicketRequest({
    required this.kind,

    required this.body,

    this.templateId,

    this.setStatus,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final AdminReplyTicketRequestKindEnum kind;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'template_id', required: false, includeIfNull: false)
  final String? templateId;

  @JsonKey(name: r'set_status', required: false, includeIfNull: false)
  final TicketStatus? setStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminReplyTicketRequest &&
          other.kind == kind &&
          other.body == body &&
          other.templateId == templateId &&
          other.setStatus == setStatus;

  @override
  int get hashCode =>
      kind.hashCode + body.hashCode + templateId.hashCode + setStatus.hashCode;

  factory AdminReplyTicketRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminReplyTicketRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminReplyTicketRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminReplyTicketRequestKindEnum {
  @JsonValue(r'reply')
  reply(r'reply'),
  @JsonValue(r'internal_note')
  internalNote(r'internal_note');

  const AdminReplyTicketRequestKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
