//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'restore_purchases_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RestorePurchasesRequest {
  /// Returns a new [RestorePurchasesRequest] instance.
  RestorePurchasesRequest({required this.channel, required this.receipts});

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final RestorePurchasesRequestChannelEnum channel;

  @JsonKey(name: r'receipts', required: true, includeIfNull: false)
  final List<String> receipts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestorePurchasesRequest &&
          other.channel == channel &&
          other.receipts == receipts;

  @override
  int get hashCode => channel.hashCode + receipts.hashCode;

  factory RestorePurchasesRequest.fromJson(Map<String, dynamic> json) =>
      _$RestorePurchasesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RestorePurchasesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RestorePurchasesRequestChannelEnum {
  @JsonValue(r'google_play')
  googlePlay(r'google_play'),
  @JsonValue(r'app_store')
  appStore(r'app_store');

  const RestorePurchasesRequestChannelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
