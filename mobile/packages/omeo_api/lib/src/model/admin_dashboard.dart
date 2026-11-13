//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_dashboard_retention.dart';
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/kpi_series.dart';
import 'package:omeo_api/src/model/admin_dashboard_active_users.dart';
import 'package:omeo_api/src/model/admin_dashboard_revenue_by_channel_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_dashboard.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDashboard {
  /// Returns a new [AdminDashboard] instance.
  AdminDashboard({
    this.signups,

    this.activeUsers,

    this.retention,

    this.trialToPlusRate,

    this.revenueByChannel,

    this.mrr,

    this.analyses,

    this.aiCost,

    this.negativeFeedbackRate,

    this.supportPending,
  });

  @JsonKey(name: r'signups', required: false, includeIfNull: false)
  final KpiSeries? signups;

  @JsonKey(name: r'active_users', required: false, includeIfNull: false)
  final AdminDashboardActiveUsers? activeUsers;

  @JsonKey(name: r'retention', required: false, includeIfNull: false)
  final AdminDashboardRetention? retention;

  @JsonKey(name: r'trial_to_plus_rate', required: false, includeIfNull: false)
  final num? trialToPlusRate;

  @JsonKey(name: r'revenue_by_channel', required: false, includeIfNull: false)
  final List<AdminDashboardRevenueByChannelInner>? revenueByChannel;

  @JsonKey(name: r'mrr', required: false, includeIfNull: false)
  final Money? mrr;

  @JsonKey(name: r'analyses', required: false, includeIfNull: false)
  final KpiSeries? analyses;

  @JsonKey(name: r'ai_cost', required: false, includeIfNull: false)
  final Money? aiCost;

  @JsonKey(
    name: r'negative_feedback_rate',
    required: false,
    includeIfNull: false,
  )
  final num? negativeFeedbackRate;

  @JsonKey(name: r'support_pending', required: false, includeIfNull: false)
  final int? supportPending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboard &&
          other.signups == signups &&
          other.activeUsers == activeUsers &&
          other.retention == retention &&
          other.trialToPlusRate == trialToPlusRate &&
          other.revenueByChannel == revenueByChannel &&
          other.mrr == mrr &&
          other.analyses == analyses &&
          other.aiCost == aiCost &&
          other.negativeFeedbackRate == negativeFeedbackRate &&
          other.supportPending == supportPending;

  @override
  int get hashCode =>
      (signups == null ? 0 : signups.hashCode) +
      (activeUsers == null ? 0 : activeUsers.hashCode) +
      (retention == null ? 0 : retention.hashCode) +
      (trialToPlusRate == null ? 0 : trialToPlusRate.hashCode) +
      (revenueByChannel == null ? 0 : revenueByChannel.hashCode) +
      (mrr == null ? 0 : mrr.hashCode) +
      (analyses == null ? 0 : analyses.hashCode) +
      (aiCost == null ? 0 : aiCost.hashCode) +
      (negativeFeedbackRate == null ? 0 : negativeFeedbackRate.hashCode) +
      (supportPending == null ? 0 : supportPending.hashCode);

  factory AdminDashboard.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDashboardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
