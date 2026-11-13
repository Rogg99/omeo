//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/ticket_category.dart';
import 'package:omeo_api/src/model/ticket_input_meta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TicketInput {
  /// Returns a new [TicketInput] instance.
  TicketInput({
    required this.category,

    required this.subject,

    required this.message,

    this.email,

    this.name,

    this.attachmentIds,

    this.captcha,

    this.meta,
  });

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final TicketCategory category;

  @JsonKey(name: r'subject', required: true, includeIfNull: false)
  final String subject;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  /// Requis sans authentification
  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @JsonKey(name: r'attachment_ids', required: false, includeIfNull: false)
  final List<String>? attachmentIds;

  /// Requis sans authentification
  @JsonKey(name: r'captcha', required: false, includeIfNull: false)
  final String? captcha;

  @JsonKey(name: r'meta', required: false, includeIfNull: false)
  final TicketInputMeta? meta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketInput &&
          other.category == category &&
          other.subject == subject &&
          other.message == message &&
          other.email == email &&
          other.name == name &&
          other.attachmentIds == attachmentIds &&
          other.captcha == captcha &&
          other.meta == meta;

  @override
  int get hashCode =>
      category.hashCode +
      subject.hashCode +
      message.hashCode +
      email.hashCode +
      name.hashCode +
      attachmentIds.hashCode +
      captcha.hashCode +
      meta.hashCode;

  factory TicketInput.fromJson(Map<String, dynamic> json) =>
      _$TicketInputFromJson(json);

  Map<String, dynamic> toJson() => _$TicketInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
