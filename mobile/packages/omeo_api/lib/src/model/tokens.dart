//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tokens.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Tokens {
  /// Returns a new [Tokens] instance.
  Tokens({
    required this.access,

    required this.refresh,

    required this.accessExpiresAt,
  });

  @JsonKey(name: r'access', required: true, includeIfNull: false)
  final String access;

  @JsonKey(name: r'refresh', required: true, includeIfNull: false)
  final String refresh;

  @JsonKey(name: r'access_expires_at', required: true, includeIfNull: false)
  final DateTime accessExpiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tokens &&
          other.access == access &&
          other.refresh == refresh &&
          other.accessExpiresAt == accessExpiresAt;

  @override
  int get hashCode =>
      access.hashCode + refresh.hashCode + accessExpiresAt.hashCode;

  factory Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);

  Map<String, dynamic> toJson() => _$TokensToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
