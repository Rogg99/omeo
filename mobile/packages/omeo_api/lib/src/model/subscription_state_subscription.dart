//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/subscription_status.dart';
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_state_subscription.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionStateSubscription {
  /// Returns a new [SubscriptionStateSubscription] instance.
  SubscriptionStateSubscription({
    required this.planCode,

    this.planName,

    required this.channel,

    required this.status,

    required this.currentPeriodEnd,

    required this.autoRenew,

    this.price,
  });

  @JsonKey(name: r'plan_code', required: true, includeIfNull: false)
  final String planCode;

  @JsonKey(name: r'plan_name', required: false, includeIfNull: false)
  final String? planName;

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final Channel channel;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final SubscriptionStatus status;

  @JsonKey(name: r'current_period_end', required: true, includeIfNull: false)
  final DateTime currentPeriodEnd;

  @JsonKey(name: r'auto_renew', required: true, includeIfNull: false)
  final bool autoRenew;

  @JsonKey(name: r'price', required: false, includeIfNull: false)
  final Money? price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStateSubscription &&
          other.planCode == planCode &&
          other.planName == planName &&
          other.channel == channel &&
          other.status == status &&
          other.currentPeriodEnd == currentPeriodEnd &&
          other.autoRenew == autoRenew &&
          other.price == price;

  @override
  int get hashCode =>
      planCode.hashCode +
      planName.hashCode +
      channel.hashCode +
      status.hashCode +
      currentPeriodEnd.hashCode +
      autoRenew.hashCode +
      price.hashCode;

  factory SubscriptionStateSubscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStateSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionStateSubscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
