//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_billing.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsBilling {
  /// Returns a new [SettingsBilling] instance.
  SettingsBilling({this.refundApprovalThresholdUsd = 50});

  @JsonKey(
    defaultValue: 50,
    name: r'refund_approval_threshold_usd',
    required: false,
    includeIfNull: false,
  )
  final num? refundApprovalThresholdUsd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsBilling &&
          other.refundApprovalThresholdUsd == refundApprovalThresholdUsd;

  @override
  int get hashCode => refundApprovalThresholdUsd.hashCode;

  factory SettingsBilling.fromJson(Map<String, dynamic> json) =>
      _$SettingsBillingFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsBillingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
