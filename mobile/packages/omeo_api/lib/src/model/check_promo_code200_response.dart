//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/money.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_promo_code200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckPromoCode200Response {
  /// Returns a new [CheckPromoCode200Response] instance.
  CheckPromoCode200Response({
    required this.valid,

    this.label,

    this.original,

    this.discounted,
  });

  @JsonKey(name: r'valid', required: true, includeIfNull: false)
  final bool valid;

  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  @JsonKey(name: r'original', required: false, includeIfNull: false)
  final Money? original;

  @JsonKey(name: r'discounted', required: false, includeIfNull: false)
  final Money? discounted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckPromoCode200Response &&
          other.valid == valid &&
          other.label == label &&
          other.original == original &&
          other.discounted == discounted;

  @override
  int get hashCode =>
      valid.hashCode + label.hashCode + original.hashCode + discounted.hashCode;

  factory CheckPromoCode200Response.fromJson(Map<String, dynamic> json) =>
      _$CheckPromoCode200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckPromoCode200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
