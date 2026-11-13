//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_user_detail_all_of_stats.dart';
import 'package:omeo_api/src/model/ticket_summary.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/subscription_state.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/session.dart';
import 'package:omeo_api/src/model/plan_tier.dart';
import 'package:omeo_api/src/model/referral_overview.dart';
import 'package:omeo_api/src/model/consent_state.dart';
import 'package:omeo_api/src/model/payment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserDetail {
  /// Returns a new [AdminUserDetail] instance.
  AdminUserDetail({
    required this.id,

    required this.email,

    required this.name,

    this.country,

    this.locale,

    required this.tier,

    required this.status,

    this.platform,

    this.lastSeenAt,

    required this.createdAt,

    this.emailVerified,

    this.goals,

    this.healthMasked,

    this.subscription,

    this.payments,

    this.referral,

    this.sessions,

    this.consents,

    this.tickets,

    this.stats,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'tier', required: true, includeIfNull: false)
  final PlanTier tier;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdminUserDetailStatusEnum status;

  @JsonKey(name: r'platform', required: false, includeIfNull: false)
  final String? platform;

  @JsonKey(name: r'last_seen_at', required: false, includeIfNull: false)
  final DateTime? lastSeenAt;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'email_verified', required: false, includeIfNull: false)
  final bool? emailVerified;

  @JsonKey(name: r'goals', required: false, includeIfNull: false)
  final List<Goal>? goals;

  /// Toujours true : les données de santé restent masquées dans cette vue
  @JsonKey(name: r'health_masked', required: false, includeIfNull: false)
  final bool? healthMasked;

  @JsonKey(name: r'subscription', required: false, includeIfNull: false)
  final SubscriptionState? subscription;

  @JsonKey(name: r'payments', required: false, includeIfNull: false)
  final List<Payment>? payments;

  @JsonKey(name: r'referral', required: false, includeIfNull: false)
  final ReferralOverview? referral;

  @JsonKey(name: r'sessions', required: false, includeIfNull: false)
  final List<Session>? sessions;

  @JsonKey(name: r'consents', required: false, includeIfNull: false)
  final List<ConsentState>? consents;

  @JsonKey(name: r'tickets', required: false, includeIfNull: false)
  final List<TicketSummary>? tickets;

  @JsonKey(name: r'stats', required: false, includeIfNull: false)
  final AdminUserDetailAllOfStats? stats;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserDetail &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.country == country &&
          other.locale == locale &&
          other.tier == tier &&
          other.status == status &&
          other.platform == platform &&
          other.lastSeenAt == lastSeenAt &&
          other.createdAt == createdAt &&
          other.emailVerified == emailVerified &&
          other.goals == goals &&
          other.healthMasked == healthMasked &&
          other.subscription == subscription &&
          other.payments == payments &&
          other.referral == referral &&
          other.sessions == sessions &&
          other.consents == consents &&
          other.tickets == tickets &&
          other.stats == stats;

  @override
  int get hashCode =>
      id.hashCode +
      email.hashCode +
      name.hashCode +
      (country == null ? 0 : country.hashCode) +
      locale.hashCode +
      tier.hashCode +
      status.hashCode +
      (platform == null ? 0 : platform.hashCode) +
      (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
      createdAt.hashCode +
      emailVerified.hashCode +
      goals.hashCode +
      healthMasked.hashCode +
      subscription.hashCode +
      payments.hashCode +
      referral.hashCode +
      sessions.hashCode +
      consents.hashCode +
      tickets.hashCode +
      stats.hashCode;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminUserDetailStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'suspended')
  suspended(r'suspended'),
  @JsonValue(r'deletion_pending')
  deletionPending(r'deletion_pending');

  const AdminUserDetailStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
