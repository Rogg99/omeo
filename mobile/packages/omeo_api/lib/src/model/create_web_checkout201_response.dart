//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_web_checkout201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateWebCheckout201Response {
  /// Returns a new [CreateWebCheckout201Response] instance.
  CreateWebCheckout201Response({
    required this.checkoutUrl,

    required this.expiresAt,
  });

  @JsonKey(name: r'checkout_url', required: true, includeIfNull: false)
  final String checkoutUrl;

  @JsonKey(name: r'expires_at', required: true, includeIfNull: false)
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateWebCheckout201Response &&
          other.checkoutUrl == checkoutUrl &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => checkoutUrl.hashCode + expiresAt.hashCode;

  factory CreateWebCheckout201Response.fromJson(Map<String, dynamic> json) =>
      _$CreateWebCheckout201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateWebCheckout201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
