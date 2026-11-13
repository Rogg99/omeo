//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'google_play_purchase_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GooglePlayPurchaseInput {
  /// Returns a new [GooglePlayPurchaseInput] instance.
  GooglePlayPurchaseInput({
    required this.channel,

    required this.productId,

    required this.purchaseToken,
  });

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final GooglePlayPurchaseInputChannelEnum channel;

  @JsonKey(name: r'product_id', required: true, includeIfNull: false)
  final String productId;

  @JsonKey(name: r'purchase_token', required: true, includeIfNull: false)
  final String purchaseToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GooglePlayPurchaseInput &&
          other.channel == channel &&
          other.productId == productId &&
          other.purchaseToken == purchaseToken;

  @override
  int get hashCode =>
      channel.hashCode + productId.hashCode + purchaseToken.hashCode;

  factory GooglePlayPurchaseInput.fromJson(Map<String, dynamic> json) =>
      _$GooglePlayPurchaseInputFromJson(json);

  Map<String, dynamic> toJson() => _$GooglePlayPurchaseInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GooglePlayPurchaseInputChannelEnum {
  @JsonValue(r'google_play')
  googlePlay(r'google_play');

  const GooglePlayPurchaseInputChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
