//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_payment_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPaymentRow {
  /// Returns a new [AdminPaymentRow] instance.
  AdminPaymentRow({
    required this.id,

    required this.channel,

    this.description,

    required this.amount,

    required this.status,

    required this.paidAt,

    this.receiptUrl,

    this.userId,

    this.userEmail,

    this.externalId,

    this.refundable,

    this.refunded,
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
  final AdminPaymentRowStatusEnum status;

  @JsonKey(name: r'paid_at', required: true, includeIfNull: false)
  final DateTime paidAt;

  @JsonKey(name: r'receipt_url', required: false, includeIfNull: false)
  final String? receiptUrl;

  @JsonKey(name: r'user_id', required: false, includeIfNull: false)
  final String? userId;

  @JsonKey(name: r'user_email', required: false, includeIfNull: false)
  final String? userEmail;

  @JsonKey(name: r'external_id', required: false, includeIfNull: false)
  final String? externalId;

  @JsonKey(name: r'refundable', required: false, includeIfNull: false)
  final bool? refundable;

  @JsonKey(name: r'refunded', required: false, includeIfNull: false)
  final Money? refunded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPaymentRow &&
          other.id == id &&
          other.channel == channel &&
          other.description == description &&
          other.amount == amount &&
          other.status == status &&
          other.paidAt == paidAt &&
          other.receiptUrl == receiptUrl &&
          other.userId == userId &&
          other.userEmail == userEmail &&
          other.externalId == externalId &&
          other.refundable == refundable &&
          other.refunded == refunded;

  @override
  int get hashCode =>
      id.hashCode +
      channel.hashCode +
      description.hashCode +
      amount.hashCode +
      status.hashCode +
      paidAt.hashCode +
      (receiptUrl == null ? 0 : receiptUrl.hashCode) +
      userId.hashCode +
      userEmail.hashCode +
      externalId.hashCode +
      refundable.hashCode +
      (refunded == null ? 0 : refunded.hashCode);

  factory AdminPaymentRow.fromJson(Map<String, dynamic> json) =>
      _$AdminPaymentRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPaymentRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminPaymentRowStatusEnum {
  @JsonValue(r'succeeded')
  succeeded(r'succeeded'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'refunded')
  refunded(r'refunded'),
  @JsonValue(r'pending')
  pending(r'pending');

  const AdminPaymentRowStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
