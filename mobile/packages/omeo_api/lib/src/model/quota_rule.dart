//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/plan_tier.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quota_rule.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuotaRule {
  /// Returns a new [QuotaRule] instance.
  QuotaRule({
    required this.planTier,

    required this.feature,

    required this.limit,

    required this.period,
  });

  @JsonKey(name: r'plan_tier', required: true, includeIfNull: false)
  final PlanTier planTier;

  @JsonKey(name: r'feature', required: true, includeIfNull: false)
  final QuotaRuleFeatureEnum feature;

  // minimum: 0
  @JsonKey(name: r'limit', required: true, includeIfNull: true)
  final int? limit;

  @JsonKey(name: r'period', required: true, includeIfNull: false)
  final QuotaRulePeriodEnum period;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotaRule &&
          other.planTier == planTier &&
          other.feature == feature &&
          other.limit == limit &&
          other.period == period;

  @override
  int get hashCode =>
      planTier.hashCode +
      feature.hashCode +
      (limit == null ? 0 : limit.hashCode) +
      period.hashCode;

  factory QuotaRule.fromJson(Map<String, dynamic> json) =>
      _$QuotaRuleFromJson(json);

  Map<String, dynamic> toJson() => _$QuotaRuleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuotaRuleFeatureEnum {
  @JsonValue(r'photo_analysis')
  photoAnalysis(r'photo_analysis'),
  @JsonValue(r'text_analysis')
  textAnalysis(r'text_analysis'),
  @JsonValue(r'challenges_active')
  challengesActive(r'challenges_active');

  const QuotaRuleFeatureEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum QuotaRulePeriodEnum {
  @JsonValue(r'day')
  day(r'day'),
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'trial')
  trial(r'trial');

  const QuotaRulePeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
