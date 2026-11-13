//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/badge_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'challenge_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChallengeSummary {
  /// Returns a new [ChallengeSummary] instance.
  ChallengeSummary({
    required this.id,

    required this.name,

    this.description,

    required this.durationDays,

    required this.ruleLabel,

    required this.validation,

    this.successThresholdPercent,

    this.points,

    this.badge,

    this.cover,

    this.joined,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'duration_days', required: true, includeIfNull: false)
  final int durationDays;

  @JsonKey(name: r'rule_label', required: true, includeIfNull: false)
  final String ruleLabel;

  @JsonKey(name: r'validation', required: true, includeIfNull: false)
  final ChallengeSummaryValidationEnum validation;

  @JsonKey(
    name: r'success_threshold_percent',
    required: false,
    includeIfNull: false,
  )
  final int? successThresholdPercent;

  @JsonKey(name: r'points', required: false, includeIfNull: false)
  final int? points;

  @JsonKey(name: r'badge', required: false, includeIfNull: false)
  final BadgeRef? badge;

  @JsonKey(name: r'cover', required: false, includeIfNull: false)
  final Image? cover;

  @JsonKey(name: r'joined', required: false, includeIfNull: false)
  final bool? joined;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeSummary &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.durationDays == durationDays &&
          other.ruleLabel == ruleLabel &&
          other.validation == validation &&
          other.successThresholdPercent == successThresholdPercent &&
          other.points == points &&
          other.badge == badge &&
          other.cover == cover &&
          other.joined == joined;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      description.hashCode +
      durationDays.hashCode +
      ruleLabel.hashCode +
      validation.hashCode +
      successThresholdPercent.hashCode +
      points.hashCode +
      badge.hashCode +
      cover.hashCode +
      joined.hashCode;

  factory ChallengeSummary.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ChallengeSummaryValidationEnum {
  @JsonValue(r'auto')
  auto(r'auto'),
  @JsonValue(r'manual')
  manual(r'manual');

  const ChallengeSummaryValidationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
