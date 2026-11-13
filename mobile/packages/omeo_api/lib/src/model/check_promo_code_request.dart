//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_promo_code_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckPromoCodeRequest {
  /// Returns a new [CheckPromoCodeRequest] instance.
  CheckPromoCodeRequest({required this.code, required this.planCode});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'plan_code', required: true, includeIfNull: false)
  final CheckPromoCodeRequestPlanCodeEnum planCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckPromoCodeRequest &&
          other.code == code &&
          other.planCode == planCode;

  @override
  int get hashCode => code.hashCode + planCode.hashCode;

  factory CheckPromoCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckPromoCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckPromoCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CheckPromoCodeRequestPlanCodeEnum {
  @JsonValue(r'plus_monthly')
  plusMonthly(r'plus_monthly'),
  @JsonValue(r'plus_annual')
  plusAnnual(r'plus_annual');

  const CheckPromoCodeRequestPlanCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
