//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_detail_all_of_messages.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TicketDetailAllOfMessages {
  /// Returns a new [TicketDetailAllOfMessages] instance.
  TicketDetailAllOfMessages({
    required this.id,

    required this.direction,

    this.author,

    required this.body,

    this.attachments,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'direction', required: true, includeIfNull: false)
  final TicketDetailAllOfMessagesDirectionEnum direction;

  @JsonKey(name: r'author', required: false, includeIfNull: false)
  final String? author;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'attachments', required: false, includeIfNull: false)
  final List<Image>? attachments;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketDetailAllOfMessages &&
          other.id == id &&
          other.direction == direction &&
          other.author == author &&
          other.body == body &&
          other.attachments == attachments &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      direction.hashCode +
      (author == null ? 0 : author.hashCode) +
      body.hashCode +
      attachments.hashCode +
      createdAt.hashCode;

  factory TicketDetailAllOfMessages.fromJson(Map<String, dynamic> json) =>
      _$TicketDetailAllOfMessagesFromJson(json);

  Map<String, dynamic> toJson() => _$TicketDetailAllOfMessagesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TicketDetailAllOfMessagesDirectionEnum {
  @JsonValue(r'inbound')
  inbound(r'inbound'),
  @JsonValue(r'outbound')
  outbound(r'outbound'),
  @JsonValue(r'internal_note')
  internalNote(r'internal_note');

  const TicketDetailAllOfMessagesDirectionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
