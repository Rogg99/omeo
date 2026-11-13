//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_store_purchase_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppStorePurchaseInput {
  /// Returns a new [AppStorePurchaseInput] instance.
  AppStorePurchaseInput({
    required this.channel,

    required this.signedTransaction,
  });

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final AppStorePurchaseInputChannelEnum channel;

  /// JWS StoreKit 2
  @JsonKey(name: r'signed_transaction', required: true, includeIfNull: false)
  final String signedTransaction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStorePurchaseInput &&
          other.channel == channel &&
          other.signedTransaction == signedTransaction;

  @override
  int get hashCode => channel.hashCode + signedTransaction.hashCode;

  factory AppStorePurchaseInput.fromJson(Map<String, dynamic> json) =>
      _$AppStorePurchaseInputFromJson(json);

  Map<String, dynamic> toJson() => _$AppStorePurchaseInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AppStorePurchaseInputChannelEnum {
  @JsonValue(r'app_store')
  appStore(r'app_store');

  const AppStorePurchaseInputChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
