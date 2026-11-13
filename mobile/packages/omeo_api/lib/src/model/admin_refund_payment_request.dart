//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_refund_payment_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminRefundPaymentRequest {
  /// Returns a new [AdminRefundPaymentRequest] instance.
  AdminRefundPaymentRequest({
    this.amountCents,

    this.confirm,

    required this.reason,
  });

  /// Défaut : total
  // minimum: 1
  @JsonKey(name: r'amount_cents', required: false, includeIfNull: false)
  final int? amountCents;

  /// Email de l'utilisateur, pour un remboursement complet
  @JsonKey(name: r'confirm', required: false, includeIfNull: false)
  final String? confirm;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRefundPaymentRequest &&
          other.amountCents == amountCents &&
          other.confirm == confirm &&
          other.reason == reason;

  @override
  int get hashCode => amountCents.hashCode + confirm.hashCode + reason.hashCode;

  factory AdminRefundPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminRefundPaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminRefundPaymentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
