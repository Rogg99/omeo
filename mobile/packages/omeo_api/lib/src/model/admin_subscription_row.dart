//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/subscription_status.dart';
import 'package:omeo_api/src/model/channel.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_subscription_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSubscriptionRow {
  /// Returns a new [AdminSubscriptionRow] instance.
  AdminSubscriptionRow({
    required this.id,

    required this.userId,

    required this.userEmail,

    required this.planCode,

    required this.channel,

    required this.status,

    this.currentPeriodEnd,

    this.autoRenew,

    this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'user_id', required: true, includeIfNull: false)
  final String userId;

  @JsonKey(name: r'user_email', required: true, includeIfNull: false)
  final String userEmail;

  @JsonKey(name: r'plan_code', required: true, includeIfNull: false)
  final String planCode;

  @JsonKey(name: r'channel', required: true, includeIfNull: false)
  final Channel channel;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final SubscriptionStatus status;

  @JsonKey(name: r'current_period_end', required: false, includeIfNull: false)
  final DateTime? currentPeriodEnd;

  @JsonKey(name: r'auto_renew', required: false, includeIfNull: false)
  final bool? autoRenew;

  @JsonKey(name: r'created_at', required: false, includeIfNull: false)
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSubscriptionRow &&
          other.id == id &&
          other.userId == userId &&
          other.userEmail == userEmail &&
          other.planCode == planCode &&
          other.channel == channel &&
          other.status == status &&
          other.currentPeriodEnd == currentPeriodEnd &&
          other.autoRenew == autoRenew &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      userId.hashCode +
      userEmail.hashCode +
      planCode.hashCode +
      channel.hashCode +
      status.hashCode +
      currentPeriodEnd.hashCode +
      autoRenew.hashCode +
      createdAt.hashCode;

  factory AdminSubscriptionRow.fromJson(Map<String, dynamic> json) =>
      _$AdminSubscriptionRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSubscriptionRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
