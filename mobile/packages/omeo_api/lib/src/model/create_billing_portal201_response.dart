//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_billing_portal201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateBillingPortal201Response {
  /// Returns a new [CreateBillingPortal201Response] instance.
  CreateBillingPortal201Response({required this.url});

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateBillingPortal201Response && other.url == url;

  @override
  int get hashCode => url.hashCode;

  factory CreateBillingPortal201Response.fromJson(Map<String, dynamic> json) =>
      _$CreateBillingPortal201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBillingPortal201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
