//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/entitlements.dart';
import 'package:omeo_api/src/model/quota.dart';
import 'package:omeo_api/src/model/subscription_state_subscription.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_state.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionState {
  /// Returns a new [SubscriptionState] instance.
  SubscriptionState({
    required this.entitlements,

    this.subscription,

    this.trialDaysLeft,

    this.grantedDaysLeft,

    required this.quotas,

    required this.canPurchaseInApp,

    required this.canManage,

    this.webCheckoutAllowed,
  });

  @JsonKey(name: r'entitlements', required: true, includeIfNull: false)
  final Entitlements entitlements;

  @JsonKey(name: r'subscription', required: false, includeIfNull: false)
  final SubscriptionStateSubscription? subscription;

  @JsonKey(name: r'trial_days_left', required: false, includeIfNull: false)
  final int? trialDaysLeft;

  @JsonKey(name: r'granted_days_left', required: false, includeIfNull: false)
  final int? grantedDaysLeft;

  @JsonKey(name: r'quotas', required: true, includeIfNull: false)
  final List<Quota> quotas;

  @JsonKey(name: r'can_purchase_in_app', required: true, includeIfNull: false)
  final bool canPurchaseInApp;

  @JsonKey(name: r'can_manage', required: true, includeIfNull: false)
  final SubscriptionStateCanManageEnum canManage;

  /// Pays autorisé à renvoyer vers le site
  @JsonKey(name: r'web_checkout_allowed', required: false, includeIfNull: false)
  final bool? webCheckoutAllowed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionState &&
          other.entitlements == entitlements &&
          other.subscription == subscription &&
          other.trialDaysLeft == trialDaysLeft &&
          other.grantedDaysLeft == grantedDaysLeft &&
          other.quotas == quotas &&
          other.canPurchaseInApp == canPurchaseInApp &&
          other.canManage == canManage &&
          other.webCheckoutAllowed == webCheckoutAllowed;

  @override
  int get hashCode =>
      entitlements.hashCode +
      (subscription == null ? 0 : subscription.hashCode) +
      (trialDaysLeft == null ? 0 : trialDaysLeft.hashCode) +
      (grantedDaysLeft == null ? 0 : grantedDaysLeft.hashCode) +
      quotas.hashCode +
      canPurchaseInApp.hashCode +
      canManage.hashCode +
      webCheckoutAllowed.hashCode;

  factory SubscriptionState.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStateFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SubscriptionStateCanManageEnum {
  @JsonValue(r'store')
  store(r'store'),
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'none')
  none(r'none');

  const SubscriptionStateCanManageEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
