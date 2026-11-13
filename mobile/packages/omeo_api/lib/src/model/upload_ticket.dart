//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_ticket.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadTicket {
  /// Returns a new [UploadTicket] instance.
  UploadTicket({
    required this.id,

    required this.uploadUrl,

    required this.method,

    required this.headers,

    required this.expiresAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'upload_url', required: true, includeIfNull: false)
  final String uploadUrl;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final UploadTicketMethodEnum method;

  @JsonKey(name: r'headers', required: true, includeIfNull: false)
  final Map<String, String> headers;

  @JsonKey(name: r'expires_at', required: true, includeIfNull: false)
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadTicket &&
          other.id == id &&
          other.uploadUrl == uploadUrl &&
          other.method == method &&
          other.headers == headers &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      id.hashCode +
      uploadUrl.hashCode +
      method.hashCode +
      headers.hashCode +
      expiresAt.hashCode;

  factory UploadTicket.fromJson(Map<String, dynamic> json) =>
      _$UploadTicketFromJson(json);

  Map<String, dynamic> toJson() => _$UploadTicketToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UploadTicketMethodEnum {
  @JsonValue(r'PUT')
  PUT(r'PUT');

  const UploadTicketMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
