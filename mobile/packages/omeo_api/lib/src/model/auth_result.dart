//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/me.dart';
import 'package:omeo_api/src/model/tokens.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthResult {
  /// Returns a new [AuthResult] instance.
  AuthResult({
    required this.tokens,

    required this.me,

    required this.created,

    this.inviteCodeStatus,
  });

  @JsonKey(name: r'tokens', required: true, includeIfNull: false)
  final Tokens tokens;

  @JsonKey(name: r'me', required: true, includeIfNull: false)
  final Me me;

  @JsonKey(name: r'created', required: true, includeIfNull: false)
  final bool created;

  @JsonKey(name: r'invite_code_status', required: false, includeIfNull: false)
  final AuthResultInviteCodeStatusEnum? inviteCodeStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResult &&
          other.tokens == tokens &&
          other.me == me &&
          other.created == created &&
          other.inviteCodeStatus == inviteCodeStatus;

  @override
  int get hashCode =>
      tokens.hashCode +
      me.hashCode +
      created.hashCode +
      inviteCodeStatus.hashCode;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AuthResultInviteCodeStatusEnum {
  @JsonValue(r'none')
  none(r'none'),
  @JsonValue(r'valid')
  valid(r'valid'),
  @JsonValue(r'invalid')
  invalid(r'invalid');

  const AuthResultInviteCodeStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
