//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'money.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Money {
  /// Returns a new [Money] instance.
  Money({required this.amountCents, required this.currency, this.formatted});

  @JsonKey(name: r'amount_cents', required: true, includeIfNull: false)
  final int amountCents;

  @JsonKey(name: r'currency', required: true, includeIfNull: false)
  final MoneyCurrencyEnum currency;

  /// Formaté selon Accept-Language
  @JsonKey(name: r'formatted', required: false, includeIfNull: false)
  final String? formatted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.amountCents == amountCents &&
          other.currency == currency &&
          other.formatted == formatted;

  @override
  int get hashCode =>
      amountCents.hashCode + currency.hashCode + formatted.hashCode;

  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  Map<String, dynamic> toJson() => _$MoneyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MoneyCurrencyEnum {
  @JsonValue(r'USD')
  USD(r'USD');

  const MoneyCurrencyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
