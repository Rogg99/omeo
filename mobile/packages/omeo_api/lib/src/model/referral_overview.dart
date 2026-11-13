//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/referral_overview_referees_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReferralOverview {
  /// Returns a new [ReferralOverview] instance.
  ReferralOverview({
    required this.code,

    required this.shareUrl,

    required this.shareMessage,

    required this.validatedCount,

    this.pendingCount,

    required this.daysEarned,

    required this.daysCap,

    this.referees,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'share_url', required: true, includeIfNull: false)
  final String shareUrl;

  @JsonKey(name: r'share_message', required: true, includeIfNull: false)
  final String shareMessage;

  @JsonKey(name: r'validated_count', required: true, includeIfNull: false)
  final int validatedCount;

  @JsonKey(name: r'pending_count', required: false, includeIfNull: false)
  final int? pendingCount;

  @JsonKey(name: r'days_earned', required: true, includeIfNull: false)
  final int daysEarned;

  @JsonKey(name: r'days_cap', required: true, includeIfNull: false)
  final int daysCap;

  @JsonKey(name: r'referees', required: false, includeIfNull: false)
  final List<ReferralOverviewRefereesInner>? referees;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralOverview &&
          other.code == code &&
          other.shareUrl == shareUrl &&
          other.shareMessage == shareMessage &&
          other.validatedCount == validatedCount &&
          other.pendingCount == pendingCount &&
          other.daysEarned == daysEarned &&
          other.daysCap == daysCap &&
          other.referees == referees;

  @override
  int get hashCode =>
      code.hashCode +
      shareUrl.hashCode +
      shareMessage.hashCode +
      validatedCount.hashCode +
      pendingCount.hashCode +
      daysEarned.hashCode +
      daysCap.hashCode +
      referees.hashCode;

  factory ReferralOverview.fromJson(Map<String, dynamic> json) =>
      _$ReferralOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
