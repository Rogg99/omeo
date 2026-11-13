//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verify_store_purchase_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerifyStorePurchaseRequest {
  /// Returns a new [VerifyStorePurchaseRequest] instance.
  VerifyStorePurchaseRequest({
    required this.channel,

    required this.productId,

    required this.purchaseToken,

    required this.signedTransaction,
  });

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final VerifyStorePurchaseRequestChannelEnum channel;

  @JsonKey(name: r'product_id', required: true, includeIfNull: false)
  final String productId;

  @JsonKey(name: r'purchase_token', required: true, includeIfNull: false)
  final String purchaseToken;

  /// JWS StoreKit 2
  @JsonKey(name: r'signed_transaction', required: true, includeIfNull: false)
  final String signedTransaction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifyStorePurchaseRequest &&
          other.channel == channel &&
          other.productId == productId &&
          other.purchaseToken == purchaseToken &&
          other.signedTransaction == signedTransaction;

  @override
  int get hashCode =>
      channel.hashCode +
      productId.hashCode +
      purchaseToken.hashCode +
      signedTransaction.hashCode;

  factory VerifyStorePurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyStorePurchaseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyStorePurchaseRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum VerifyStorePurchaseRequestChannelEnum {
  @JsonValue(r'app_store')
  appStore(r'app_store');

  const VerifyStorePurchaseRequestChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
