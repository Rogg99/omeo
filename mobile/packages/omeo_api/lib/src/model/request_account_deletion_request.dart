//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request_account_deletion_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RequestAccountDeletionRequest {
  /// Returns a new [RequestAccountDeletionRequest] instance.
  RequestAccountDeletionRequest({
    required this.confirm,

    this.password,

    this.reason,
  });

  @JsonKey(name: r'confirm', required: true, includeIfNull: false)
  final RequestAccountDeletionRequestConfirmEnum confirm;

  /// Requis si le compte a un mot de passe
  @JsonKey(name: r'password', required: false, includeIfNull: false)
  final String? password;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestAccountDeletionRequest &&
          other.confirm == confirm &&
          other.password == password &&
          other.reason == reason;

  @override
  int get hashCode => confirm.hashCode + password.hashCode + reason.hashCode;

  factory RequestAccountDeletionRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestAccountDeletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RequestAccountDeletionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RequestAccountDeletionRequestConfirmEnum {
  @JsonValue(r'DELETE')
  DELETE(r'DELETE');

  const RequestAccountDeletionRequestConfirmEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
