//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quota.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Quota {
  /// Returns a new [Quota] instance.
  Quota({
    required this.feature,

    required this.limit,

    required this.used,

    required this.remaining,

    required this.period,

    this.resetsAt,
  });

  @JsonKey(name: r'feature', required: true, includeIfNull: false)
  final QuotaFeatureEnum feature;

  @JsonKey(name: r'limit', required: true, includeIfNull: true)
  final int? limit;

  @JsonKey(name: r'used', required: true, includeIfNull: false)
  final int used;

  @JsonKey(name: r'remaining', required: true, includeIfNull: true)
  final int? remaining;

  @JsonKey(name: r'period', required: true, includeIfNull: false)
  final QuotaPeriodEnum period;

  @JsonKey(name: r'resets_at', required: false, includeIfNull: false)
  final DateTime? resetsAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quota &&
          other.feature == feature &&
          other.limit == limit &&
          other.used == used &&
          other.remaining == remaining &&
          other.period == period &&
          other.resetsAt == resetsAt;

  @override
  int get hashCode =>
      feature.hashCode +
      (limit == null ? 0 : limit.hashCode) +
      used.hashCode +
      (remaining == null ? 0 : remaining.hashCode) +
      period.hashCode +
      (resetsAt == null ? 0 : resetsAt.hashCode);

  factory Quota.fromJson(Map<String, dynamic> json) => _$QuotaFromJson(json);

  Map<String, dynamic> toJson() => _$QuotaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuotaFeatureEnum {
  @JsonValue(r'photo_analysis')
  photoAnalysis(r'photo_analysis'),
  @JsonValue(r'text_analysis')
  textAnalysis(r'text_analysis'),
  @JsonValue(r'challenges_active')
  challengesActive(r'challenges_active');

  const QuotaFeatureEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum QuotaPeriodEnum {
  @JsonValue(r'day')
  day(r'day'),
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'trial')
  trial(r'trial');

  const QuotaPeriodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
