//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard_revenue_by_channel_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDashboardRevenueByChannelInner {
  /// Returns a new [AdminDashboardRevenueByChannelInner] instance.
  AdminDashboardRevenueByChannelInner({this.channel, this.amount});

  @JsonKey(name: r'channel', required: false, includeIfNull: false)
  final Channel? channel;

  @JsonKey(name: r'amount', required: false, includeIfNull: false)
  final Money? amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboardRevenueByChannelInner &&
          other.channel == channel &&
          other.amount == amount;

  @override
  int get hashCode => channel.hashCode + amount.hashCode;

  factory AdminDashboardRevenueByChannelInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminDashboardRevenueByChannelInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminDashboardRevenueByChannelInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
