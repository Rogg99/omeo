//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_web_checkout_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateWebCheckoutRequest {
  /// Returns a new [CreateWebCheckoutRequest] instance.
  CreateWebCheckoutRequest({
    required this.planCode,

    this.promoCode,

    required this.successUrl,

    required this.cancelUrl,
  });

  @JsonKey(name: r'plan_code', required: true, includeIfNull: false)
  final CreateWebCheckoutRequestPlanCodeEnum planCode;

  @JsonKey(name: r'promo_code', required: false, includeIfNull: false)
  final String? promoCode;

  @JsonKey(name: r'success_url', required: true, includeIfNull: false)
  final String successUrl;

  @JsonKey(name: r'cancel_url', required: true, includeIfNull: false)
  final String cancelUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateWebCheckoutRequest &&
          other.planCode == planCode &&
          other.promoCode == promoCode &&
          other.successUrl == successUrl &&
          other.cancelUrl == cancelUrl;

  @override
  int get hashCode =>
      planCode.hashCode +
      promoCode.hashCode +
      successUrl.hashCode +
      cancelUrl.hashCode;

  factory CreateWebCheckoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWebCheckoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateWebCheckoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateWebCheckoutRequestPlanCodeEnum {
  @JsonValue(r'plus_monthly')
  plusMonthly(r'plus_monthly'),
  @JsonValue(r'plus_annual')
  plusAnnual(r'plus_annual');

  const CreateWebCheckoutRequestPlanCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
