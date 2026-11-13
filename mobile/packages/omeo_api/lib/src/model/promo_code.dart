//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promo_code.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromoCode {
  /// Returns a new [PromoCode] instance.
  PromoCode({
    this.id,

    required this.code,

    required this.kind,

    required this.value,

    this.planCodes,

    this.maxRedemptions,

    this.redeemedCount,

    required this.validFrom,

    this.validUntil,

    this.active,
  });

  @JsonKey(name: r'id', required: false, includeIfNull: false)
  final String? id;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PromoCodeKindEnum kind;

  // minimum: 0
  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final num value;

  @JsonKey(name: r'plan_codes', required: false, includeIfNull: false)
  final List<String>? planCodes;

  @JsonKey(name: r'max_redemptions', required: false, includeIfNull: false)
  final int? maxRedemptions;

  @JsonKey(name: r'redeemed_count', required: false, includeIfNull: false)
  final int? redeemedCount;

  @JsonKey(name: r'valid_from', required: true, includeIfNull: false)
  final DateTime validFrom;

  @JsonKey(name: r'valid_until', required: false, includeIfNull: false)
  final DateTime? validUntil;

  @JsonKey(name: r'active', required: false, includeIfNull: false)
  final bool? active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromoCode &&
          other.id == id &&
          other.code == code &&
          other.kind == kind &&
          other.value == value &&
          other.planCodes == planCodes &&
          other.maxRedemptions == maxRedemptions &&
          other.redeemedCount == redeemedCount &&
          other.validFrom == validFrom &&
          other.validUntil == validUntil &&
          other.active == active;

  @override
  int get hashCode =>
      id.hashCode +
      code.hashCode +
      kind.hashCode +
      value.hashCode +
      planCodes.hashCode +
      (maxRedemptions == null ? 0 : maxRedemptions.hashCode) +
      redeemedCount.hashCode +
      validFrom.hashCode +
      (validUntil == null ? 0 : validUntil.hashCode) +
      active.hashCode;

  factory PromoCode.fromJson(Map<String, dynamic> json) =>
      _$PromoCodeFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PromoCodeKindEnum {
  @JsonValue(r'percent')
  percent(r'percent'),
  @JsonValue(r'amount')
  amount(r'amount'),
  @JsonValue(r'free_days')
  freeDays(r'free_days');

  const PromoCodeKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
