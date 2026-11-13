//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_billing_portal_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateBillingPortalRequest {
  /// Returns a new [CreateBillingPortalRequest] instance.
  CreateBillingPortalRequest({required this.returnUrl});

  @JsonKey(name: r'return_url', required: true, includeIfNull: false)
  final String returnUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateBillingPortalRequest && other.returnUrl == returnUrl;

  @override
  int get hashCode => returnUrl.hashCode;

  factory CreateBillingPortalRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBillingPortalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBillingPortalRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
