//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request_deletion_by_email_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RequestDeletionByEmailRequest {
  /// Returns a new [RequestDeletionByEmailRequest] instance.
  RequestDeletionByEmailRequest({required this.email, required this.captcha});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// Jeton Cloudflare Turnstile
  @JsonKey(name: r'captcha', required: true, includeIfNull: false)
  final String captcha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestDeletionByEmailRequest &&
          other.email == email &&
          other.captcha == captcha;

  @override
  int get hashCode => email.hashCode + captcha.hashCode;

  factory RequestDeletionByEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestDeletionByEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RequestDeletionByEmailRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
