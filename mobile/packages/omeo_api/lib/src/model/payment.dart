//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Payment {
  /// Returns a new [Payment] instance.
  Payment({
    required this.id,

    required this.channel,

    this.description,

    required this.amount,

    required this.status,

    required this.paidAt,

    this.receiptUrl,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final Channel channel;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final Money amount;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final PaymentStatusEnum status;

  @JsonKey(name: r'paid_at', required: true, includeIfNull: false)
  final DateTime paidAt;

  @JsonKey(name: r'receipt_url', required: false, includeIfNull: false)
  final String? receiptUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          other.id == id &&
          other.channel == channel &&
          other.description == description &&
          other.amount == amount &&
          other.status == status &&
          other.paidAt == paidAt &&
          other.receiptUrl == receiptUrl;

  @override
  int get hashCode =>
      id.hashCode +
      channel.hashCode +
      description.hashCode +
      amount.hashCode +
      status.hashCode +
      paidAt.hashCode +
      (receiptUrl == null ? 0 : receiptUrl.hashCode);

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PaymentStatusEnum {
  @JsonValue(r'succeeded')
  succeeded(r'succeeded'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'refunded')
  refunded(r'refunded'),
  @JsonValue(r'pending')
  pending(r'pending');

  const PaymentStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
